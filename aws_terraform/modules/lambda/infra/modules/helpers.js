
var aws = require("aws-sdk");

// Define the config variable
var config = {};


//////////////////////////// Functions ////////////////////////////

function getAssumeRoleCredentials(awsAccountId, roleToAssumeName, externalId, callback) {

  // Get temporary credentials from STS by assuming the role
  var params = { "RoleArn": "arn:aws:iam::" + awsAccountId + ":role/" + roleToAssumeName, "ExternalId": externalId, "RoleSessionName": roleToAssumeName + "_" + awsAccountId };

  // Create the STS object
  var sts = new aws.STS();

  // Assume the role using STS
  sts.assumeRole(params, function (error, data) {

    // Check the error
    if (error) {
      
      // Call the callback and pass in the error
      callback(error, null);
    }
    else {

      // Create the credentials object
      var credentials = new aws.Credentials({ "accessKeyId": data.Credentials.AccessKeyId, "secretAccessKey": data.Credentials.SecretAccessKey, "sessionToken": data.Credentials.SessionToken });

      // Call the callback and pass in the credentials
      callback(null, credentials);
    }
  });
}

function getAllAccountJsonObjects(callback) {

  // Create a new S3 object
  var s3 = new aws.S3({ region: config.s3Region, signatureVersion: "v4"});

  // Craete the options for ths S3 object
  var options = {
    Bucket: config.bucketName,
    Prefix: config.s3Prefix
  };

  // Downlaod the file from S3
  s3.listObjects(options, function (error, data) {

    // Check the error
    if (error) {

      // Call the callback and pass in the error
      callback(error, null);
    }
    else {

      // Define an index and a return array
      var index = 0;
      var jsonArray = [];

      // Loop through the contents
      data.Contents.forEach(function (content) {

        // Get the file key
        var fileKey = content.Key;

        // Get the account JSON object
        getAccountJsonObject(fileKey, function (error, json) {

          // Check the error
          if (error) {

            // Call the callback and pass in the error
            callback(error, null);

            return;
          }
          else {

            // Add the JSON to the array
            jsonArray.push(json);

            // Increment the index
            index++;

            // Check if the index is equal to the contents length, if so then call the callback and pass in the JSON array
            if (index == data.Contents.length) { callback(null, jsonArray); }
          }
        });
      });
    }
  });
}

function getAccountJsonObject(fileKey, callback) {

  // Create a new S3 object
  var s3 = new aws.S3({ region: config.s3Region, signatureVersion: "v4"});

  // Craete the options for ths S3 object
  var options = {
    Bucket: config.bucketName,
    Key: fileKey
  };

  // Downlaod the file from S3
  s3.getObject(options, function (error, data) {

    // Check the error
    if (error) {

      // Call the callback and pass in the error
      callback(error, null);
    }
    else {

      // Parse the data body into a JSON object
      var jsonObject = JSON.parse(data.Body.toString("utf8"));

      // Call the callback and pass in the JSON object
      callback(null, jsonObject);
    }
  });
}

function getRegions(callback) {

  // Define an EC2 object
  var ec2 = new aws.EC2();

  // Get the regions
  ec2.describeRegions(function (error, data) {

    // Check the error
    if (error) {

      // Call the callback and pass in the error
      callback(error, null);
    }
    else {

      // Define a regions array
      var regions = [];

      // Loop through the regions
      data.Regions.forEach(function (region) { regions.push(region.RegionName); });

      // call the callback and pass in the regions
      callback(null, regions);
    }
  });
}

function getTag(tags, tagKey) {

  // Loop through the tags
  for (var index = 0; index < tags.length; index++) {

    // Check the imstance tag key
    if (tags[index].Key == tagKey) { return tags[index].Value; }
  }

  // No match, return null
  return null;
}


//////////////////////////// Export the module ////////////////////////////

module.exports = function (variables) {

  // Set the config object
  config = variables;

  // Return the functions
  return { getAssumeRoleCredentials, getAllAccountJsonObjects, getAccountJsonObject, getRegions, getTag };
};
