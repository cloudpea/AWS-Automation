
var aws = require("aws-sdk");

// Define the config variable
var config = {};


//////////////////////////// Functions ////////////////////////////

function getInstances(region, credentials, callback) {

  // Define an EC2 object for the current region
  var ec2 = null;
  if (credentials) {

    // Create a new EC2 object with the credentials
    ec2 = new aws.EC2({ "region": region, "credentials": credentials });
  }
  else {

    // Create a new EC2 object with the credentials
    ec2 = new aws.EC2({ "region": region });
  }

  // Define an instances placeholder
  var instances = [];

  // Defien the get maimum instances funtion
  var getMaximumInstances = function (nextToken) {

    // Create the params
    var params = { "MaxResults": 1000 };

    // Check if the next token is not null
    if (nextToken) { params.NextToken = nextToken; }

    // Get the instances
    ec2.describeInstances(params, function (error, data) {

      // Check the error
      if (error) {

        // Call the callback and pass in the error
        callback(error, null);
      }
      else {

        // Add the instances to the instances array
        data.Reservations.forEach(function (reservation) { instances = instances.concat(reservation.Instances); });

        // Check the next token
        if (data.NextToken) { getMaximumInstances(data.NextToken); } else { callback(null, instances); }
      }
    });
  };

  // Get the maximum instances
  getMaximumInstances(null);
}

function getInstance(region, instanceId, credentials, callback) {

  // Define an EC2 object for the current region
  var ec2 = null;
  if (credentials) {

    // Create a new EC2 object with the credentials
    ec2 = new aws.EC2({ "region": region, "credentials": credentials });
  }
  else {

    // Create a new EC2 object with the credentials
    ec2 = new aws.EC2({ "region": region });
  }

  // Create the params
  var params = { "InstanceIds": [instanceId] };

  // Get the instances
  ec2.describeInstances(params, function (error, data) {

    // Check the error
    if (error) {

      // Call the callback and pass in the error
      callback(error, null);
    }
    else {

      // Check the reservations first object in the array
      if (data.Reservations[0]) {

        // Get the instance
        var instance = data.Reservations[0].Instances[0];

        // Check if the instance is not null
        if (data.Reservations[0].Instances[0]) {

          // Call the callback and pass in the instance
          callback(null, instance);
        }
        else {

          // Create the error object
          var error = { "message": "No instance with ID \"" + instanceId + "\" found" };

          // Call the callback and pass in the error
          callback(error, null);
        }
      }
      else {

        // Create the error object
        var error = { "message": "No instance with ID \"" + instanceId + "\" found" };

        // Call the callback and pass in the error
        callback(error, null);
      }
    }
  });
}

function getSnapshots(region, volumeId, credentials, callback) {

  // Define an EC2 object for the current region
  var ec2 = null;
  if (credentials) {

    // Create a new EC2 object with the credentials
    ec2 = new aws.EC2({ "region": region, "credentials": credentials });
  }
  else {

    // Create a new EC2 object with the credentials
    ec2 = new aws.EC2({ "region": region });
  }

  // Define an snapshots placeholder
  var snapshots = [];

  // Defien the get maimum snapshots funtion
  var getMaximumSnapshots = function (nextToken) {

    // Create the params
    var params = { "Filters": [{ "Name": "volume-id", "Values": [volumeId] }], "MaxResults": 1000 };

    // Check if the next token is not null
    if (nextToken) { params.NextToken = nextToken; }

    // Get the snapshots
    ec2.describeSnapshots(params, function (error, data) {

      // Add the snapshots to the snapshots array
      snapshots = snapshots.concat(data.Snapshots);

      // Check the next token
      if (data.NextToken) { getMaximumSnapshots(data.NextToken); } else { callback(null, snapshots); }
    });
  };

  // Get the maximum snapshots
  getMaximumSnapshots(null);
}

function stopInstances(region, credentials, instanceIds) {

  // Define an EC2 object for the current region
  var ec2 = null;
  if (credentials) {

    // Create a new EC2 object with the credentials
    ec2 = new aws.EC2({ "region": region, "credentials": credentials });
  }
  else {

    // Create a new EC2 object with the credentials
    ec2 = new aws.EC2({ "region": region });
  }

  // Define the params
  var params = { "InstanceIds": instanceIds };

  // Create and sent the request
  var request = ec2.stopInstances(params);
  request.send();
}

function createTags(region, resourceId, currentTags, instanceTags, credentials) {

  // Define an EC2 object for the current region
  var ec2 = null;
  if (credentials) {

    // Create a new EC2 object with the credentials
    ec2 = new aws.EC2({ "region": region, "credentials": credentials });
  }
  else {

    // Create a new EC2 object with the credentials
    ec2 = new aws.EC2({ "region": region });
  }

  // Define the new tags array placeholder
  var tagsBeforeSort = [];
  var newTags = [];

  // Check if the current tags exists and if so set the new tage object to the current tags object so no tags are overeritten
  if (currentTags) { tagsBeforeSort = currentTags; }

  // Add all the instance tags to the new tags array
  if (instanceTags) { instanceTags.forEach(function (instanceTag) { tagsBeforeSort.push(instanceTag); }); }

  // Loop through the new tags
  tagsBeforeSort.forEach(function (tag) {

    // Check if the new tag key is valid and does not contains "aws:" and if so remove it, these are reserved for internal use by AWS
    if (tag.Key && tag.Key.indexOf("aws:") < 0) { newTags.push(tag); }
  });

  // Create the params
  var params = { "Resources": [resourceId], "Tags": newTags };

  // Create the tags on the resource
  var request = ec2.createTags(params);
  request.send();
}


//////////////////////////// Export the module ////////////////////////////

module.exports = function (variables) {

  // Set the config object
  config = variables;

  // Return the functions
  return { getInstances, getInstance, getSnapshots, stopInstances, createTags };
};
