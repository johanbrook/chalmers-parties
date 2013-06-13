/*
    From https://github.com/murilopolese/howmanypeoplearelooking
 */
Meteor.startup(function(){
    Dummies.remove({});
    Meteor.default_server.stream_server.register( Meteor.bindEnvironment( function(socket) {
        var intervalID = Meteor.setInterval(function() {
            if (socket.meteor_session) {

                var connection = {
                    connectionID: socket.meteor_session.id,
                    connectionAddress: socket.address,
                    userID: socket.meteor_session.userId
                };

                socket.id = socket.meteor_session.id;

                Dummies.insert(connection); 

                Meteor.clearInterval(intervalID);
            }
        }, 1000);

        socket.on('close', Meteor.bindEnvironment(function () {
            Dummies.remove({
                connectionID: socket.id
                });
        }, function(e) {
            Meteor._debug("Exception from connection close callback:", e);
        }));
    }, function(e) {
        Meteor._debug("Exception from connection registration callback:", e);
    }));
});


