const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

//MAKE SURE:
//const String USER_COLLECTION = "u";
//const String USER_DISPLAY_NAME = "u";

//const String MESSAGE_MESSAGE = "m";
//const String MESSAGE_SENDER = "s";
//const String MESSAGE_RECEIVER = "r";
//const String MESSAGE_TIMESTAMP = "t";
//const String MESSAGE_IS_READ = "x";
//const String MESSAGE_ID = "i";

//const String CHAT_USER_TOKEN = "t";
//const String CHAT_IS_CHAT_ON = "o";
//const String CHAT_SELLING = "s";
//const String CHAT_BUYING = "b";
//const String CHAT_USER_UID = "u";
//const String CHAT_MESSAGE_DUMP = "d";
//const String CHAT_PRODUCT_ID = "p";
//under global/globalItems.dart

exports.newMessage = functions.database.ref('/d/{messageDumpUuid}/{messageUuid}').onCreate((snapshot, context) => {
    const messageDumpUuid = context.params.messageDumpUuid;
    const messageUuid = context.params.messageUuid;

  	var newMessage = snapshot.val();
  	console.log(newMessage);
   	var receiverUid = newMessage.r;
   	var senderUid = newMessage.s;
   	console.log(receiverUid);

   	var token;

   	return admin.database().ref('u/' + receiverUid).once('value').then((snapshot) => {
   		userData = snapshot.val();
   		token = userData.t;
   		isChatOn = userData.o;
		isNotifsEnabled = userData.n;
   		console.log('token ' + token);
   		console.log('is chat on ' + isChatOn);

   		return token;
   	})
   	.catch((error) => {
   		console.log("getting token error: ", error);
   	})
   	.then((token) => {
   		if (token !== null && isChatOn !== "Y" && isNotifsEnabled !== "N") {
   			var senderName;

   			admin.firestore().collection('u').doc(senderUid).get().then((document) => {
   				if (document.exists) {
   					senderName = document.get('u');
   				}
   				else {
   					senderName = "";
   				}

   				var payload = {
   					notification: {
   						title: senderName,
   						body: newMessage.m
   					},
   					data: {
   						'd': messageDumpUuid
   					}
   				};

   				admin.messaging().sendToDevice(token, payload).then((response) => {
   					console.log("Message sent successfully with response: ", response);
   					return response;
   				})
   				.catch((error) => {
   					console.log("error: ", error);
   				});

   				return senderName;
   			})
   			.catch((error) => {
		   		console.log("error: ", error);
		   	});
   		}

   		return token;
   	})
   	.catch((error) => {
   		console.log("error: ", error);
   	});


});


