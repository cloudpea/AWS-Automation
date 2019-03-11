
var aws = require("aws-sdk");

// Require the customer modules
var helpers = require("./helpers.js");
var ec2 = require("./ec2.js");

// Define the config variable
var config = {};

// Define the defined tags array
var definedTags = [];



//////////////////////////// Functions ////////////////////////////

function populateResourceTagsChildResources() {

  // Create the module objects
  var helpersObject = new helpers(config);

  // Get the JSON obejct
  helpersObject.getAllAccountJsonObjects(function (error, accountJsonObjects) {

    // Check the error
    if (error == null) {

      // Get the regions
      helpersObject.getRegions(function (error, regions) {

        // Check the error
        if (error == null) {

          // Populate resource tags for the current account
          populateResourceTagsForAccount(regions, null);

          // Get the role name
          var roleName = config.childRole;

          // Loop through the accounts
          accountJsonObjects.forEach(function (subAccount) {

            // Get the account ID and external ID
            var accountId = subAccount.id;
            var externalId = subAccount.externalIds[roleName];

            // Assume the role and get the credentials for the account
            helpersObject.getAssumeRoleCredentials(accountId, roleName, externalId, function (error, credentials) {

              // Check the error
              if (error == null) {

                // Populate resource tags for account
                populateResourceTagsForAccount(regions, credentials);
              }
            });
          });
        }
      });
    }
  });
}

function populateResourceTagsOnCreation(event) {

  // Create the module objects
  var helpersObject = new helpers(config);
  var ec2Object = new ec2(config);

  // Get the log events
  var logEvent = event.detail;

  // Get the owner, AWS account ID, instance ID and region from the payload object
  var owner = logEvent.userIdentity.userName;
  var accountId = logEvent.userIdentity.accountId;
  var instanceId = logEvent.responseElements.instancesSet.items[0].instanceId;
  var region = logEvent.awsRegion;

  // Get the JSON obejct
  helpersObject.getAccountJsonObject(config.s3Prefix + "/" + accountId + ".json", function (error, accountJsonObject) {

    // Check the error
    if (error == null) {

      // Check the user type and setthe creator to "Root User" if the user type is "Root"
      if (logEvent.userIdentity.type == "Root") { owner = "Root User"; }
	  
	  // Check the user type and set the creator to the assumed if the user type is "AssumedRole"
      if (logEvent.userIdentity.type == "AssumedRole") { owner = logEvent.userIdentity.sessionContext.sessionIssuer.userName; }

      // Check if the AWS account ID is equal to the central AWS account
      if (accountId == config.centraAccountId) {

        // Get the instance
        ec2Object.getInstance(region, instanceId, null, function (error, instance) {

          // Check the error
          if (error == null) {

            // Add the tags to the resource
            addTagsToInstance(region, owner, instance, instanceId, null);
          }
        });
      }
      else {

        // Check if the account JSON objecr is not null
        if (accountJsonObject) {

          // Get the role name and the external ID
          var roleName = config.childRole;
          var externalId = accountJsonObject.externalIds[roleName];

          // Assume the role and get the credentials for the account
          helpersObject.getAssumeRoleCredentials(accountId, roleName, externalId, function (error, credentials) {

            // Check the error
            if (error == null) {

              // Get the instance
              ec2Object.getInstance(region, instanceId, credentials, function (error, instance) {

                // Check the error
                if (error == null) {

                  // Add the tags to the resource
                  addTagsToInstance(region, owner, instance, instanceId, credentials);
                }
              });
            }
          });
        }
      }
    }
  });
}

function addTagsToInstance(region, owner, instance, instanceId, credentials) {

  // Create the module objects
  var helpersObject = new helpers(config);
  var ec2Object = new ec2(config);

  // Get the owner tag and check ifit is null, if it is then set it to the owner form the log event
  var ownerTag = helpersObject.getTag(instance.Tags, "Owner");
  if (ownerTag == null) { ownerTag = owner; }

  // Define the tags to add array
  var tagsToAdd = [];
  tagsToAdd.push({ "Key": "Owner", "Value": owner });

  // Loop through the defined tags
  definedTags.forEach(function (definedTag) {

    // Get the tag from the instance, check if the tag value is null and if so set it to a blank value so it gets added
    var tagValue = helpersObject.getTag(instance.Tags, definedTag);
    if (tagValue == null) { tagValue = " "; }

    // Add the tag to the tags to add object
    tagsToAdd.push({ "Key": definedTag, "Value": tagValue });
  });

  // Create the tags
  ec2Object.createTags(region, instanceId, null, tagsToAdd, credentials);
}

function populateResourceTagsForAccount(regions, credentials) {

  // Create the module objects
  var ec2Object = new ec2(config);

  // Loop through the regions
  regions.forEach(function (region) {

    // Get the istances
    ec2Object.getInstances(region, credentials, function (error, instances) {

      // Check the error
      if (error == null) {

        // Loop through the instances
        instances.forEach(function (instance) {

          // Get the block device mappings
          var blockDeviceMappings = instance.BlockDeviceMappings;

          // Loop through block devices in block device mappings
          blockDeviceMappings.forEach(function(blockDevice) {

            // get the EBS Volume for the block device
            var ebsVolume = blockDevice.Ebs;

            // Create the tags for the EBS volume
            ec2Object.createTags(region, ebsVolume.VolumeId, ebsVolume.Tags, instance.Tags, credentials);

            // Get the snapshots
            ec2Object.getSnapshots(region, ebsVolume.VolumeId, credentials, function (error, snapshots) {

              // Check the error
              if (error == null) {

                // Loop through the snapshots
                snapshots.forEach(function (snapshot) {

                  // Create the tags for the snapshot
                  ec2Object.createTags(region, snapshot.SnapshotId, snapshot.Tags, instance.Tags, credentials);
                });
              }
            });
          });

          // Loop through the network interfaces
          instance.NetworkInterfaces.forEach(function (networkInterface) {

            // Create the tags for the network interface
            ec2Object.createTags(region, networkInterface.NetworkInterfaceId, networkInterface.Tags, instance.Tags, credentials);
          });
        });
      }
    });
  });
}


//////////////////////////// Export the module ////////////////////////////

module.exports = function (variables) {

  // Set the config object
  config = variables;

  // Set the defined tags array
  definedTags = config.tags.split(",");

  // Return the functions
  return { populateResourceTagsChildResources, populateResourceTagsOnCreation, addTagsToInstance, populateResourceTagsForAccount };
};
