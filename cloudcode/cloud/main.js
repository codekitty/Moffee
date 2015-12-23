Parse.Cloud.afterSave("CoffeeDelivered", function(request, status) {
	// update user similarity table

	username = request.object.get("username");
	coffeeshopid = request.object.get("coffeeshopid");
	var new_unique_delivery = true;

	var uqueryA = new Parse.Query("CoffeeDelivered");
	uqueryA.equalTo("username", username);
	// var uqueryB = new Parse.Query("CoffeeDelivered");
	uqueryA.equalTo("coffeeshopid", coffeeshopid);
	// var unique_delivery = Parse.Query.and(uqueryA, uqueryB);

	uqueryA.count({
		success: function(number) {
			// There are number past orders.
			// status.message("Ordered " + (number - 1) + " times from here before");
			console.log("Ordered " + (number - 1) + " times from here before");
			if (number > 1) {
				response.success("no unique additions to update");
				return;
			} else {
				var counter= 0;

				var query = new Parse.Query("CoffeeDelivered");
				query.equalTo("coffeeshopid", coffeeshopid);
				query.each(function(delivery) {

					var otheruser = delivery.get("username");
					if (otheruser !== username) {
						// increment user similarity in user similarity table
						var queryA = new Parse.Query("UserSimilarity");
						queryA.containedIn("username", [username, otheruser]);
						// var queryB = new Parse.Query("UserSimilarity");
						queryA.containedIn("otherusername", [username, otheruser]);
						// var sim_query = Parse.Query.and(queryA, queryB);

						queryA.first({
							success: function(similarity) {
								if (!similarity) {
									// create a similarity entry
				                    console.log("new similarity");
				                    var UserSimilarity = Parse.Object.extend("UserSimilarity");
									similarity = new UserSimilarity();
				                    similarity.set("username", username);
				                    similarity.set("otherusername", otheruser);
				                    similarity.set("measure", 1);
								} else {
									console.log("update measure");
									similarity.increment("measure");
								}
								similarity.save();
							},
							error: function(error) {
						      // status.error("Uh oh, something went wrong. " + error.message);
						      console.error("Got an error " + error.code + " : " + error.message);
							}
						});
					}

					if (counter % 5 === 0) {
						// Set the  job's progress status
						// status.message(counter + " users processed.");
					}
					counter += 1;

				  }).then(function() {
				    // Set the job's success status
				    // status.success("user similarities updated successfully.");
				  }, function(error) {
				    // Set the job's error status
				    // status.error("Uh oh, something went wrong. " + error.message);
				});		
			}
		},
		error: function(error) {
			new_unique_delivery = false;
			// status.error("Uh oh, something went wrong. " + error.message);
		    console.log("error");
		}
	});
});