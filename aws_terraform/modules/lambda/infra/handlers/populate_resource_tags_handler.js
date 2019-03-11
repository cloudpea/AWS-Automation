
// Require the custom modules
var populateResourceTags = require("../modules/populate_resource_tags.js");


//////////////////////////// Functions ////////////////////////////

module.exports.populateResourceTagsChildResources = function (event, context, callabck) {

  // Create the stop untagged instances object
  var populateResourceTagsObject = new populateResourceTags(process.env);

  // Call the module function
  populateResourceTagsObject.populateResourceTagsChildResources();
}

module.exports.populateResourceTagsOnCreation = function (event, context, callabck) {

  // Create the stop untagged instances object
  var populateResourceTagsObject = new populateResourceTags(process.env);

  // Call the module function
  populateResourceTagsObject.populateResourceTagsOnCreation(event);
}
