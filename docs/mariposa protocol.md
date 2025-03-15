Mariposa is a peer to peer encrypted messaging protocol built on HTTPS over TOR. Communication takes place over three main activities: contact, introduction, and messaging. Contact is the process in which users are able to create contacts for other users. It is designed to take place in person. Introduction allows users to act as intermediaries between other users. Allowing them to create contacts for users without meeting in person. Finally, messaging is the process in which users communicate. Users can send messages to single users or group chats.

Encryption takes place using AES-GCM mode with 256 bit keys. AES is used with GCM mode to prevent bit flipping attacks.

Exact data transfer formats are omitted to allow to allow for flexibility. However, all data transfer can be assumed to take place of HTTPS.

A Contact stores all the information needed to message a users. It has the following form.
- contact ID, a unique hash
- onion address for contact
- 256 bit encryption key for messages
- contact nickname, plain text

Contact is meant to take place in person. The method is a follows.
First user one creates a temporary contact and shares the following information with the user two.
- contact id - a unique 256 bit random hash
- onion address - the link the tor address for user one
- an encryption key - a 256 encryption key
This information can be shared using a QR code or passed over Bluetooth.

Using this, user two creates a contact, and sends a "initial contact" message to user ones onion address. The message is encrypted using the contact key and a initiation vector to prevent pattern analysis attacks. The contact message takes the following structure
- encrypted section
	- contact id
	- initial contact message type
		- senders onion address
- IV
Messages are decrypted by iterating contacts; Using each key until a valid message is found. Once the message is decrypted user one validates that the contact id from the message is the same one used to decrypt the message. If so that contacts onion address is updated. Additionally only messages that contain a matching contact ID are valid for all message types.

Introduction allows a user (initiator) to introduce two or more of their contacts to each other. To introduce users, you start by sending each user a list of the contacts you wish to introduce them too. The message takes the following form
- encrypted section
	- contact id
	- introduction request message type
		- introduction id
		- list of onion addresses and nicknames
- IV

If one or more users do not receive the message can be resent.

Each user now chooses to accept or decline the introduction by sending a introduction response message to the initiator.
- encrypted section
	- contact id
	- introduction response message type
		- introduction id
		- accept or decline
- IV

If a user accepts the request they will then periodically check in using an introduction status request. The initiator will return pending, initiated accepted or canceled as a response
- encrypted section
	- Contact id
	- Introduction status request message type
		- Introduction id
		- pending, accepted, initiated  or cancelled
- IV

If cancelled the initiator waits until all users have seen the cancellation 

If all users accept the introduction, a list of contacts is sent for each contact pair. These contacts are not used for messaging to prevent more than two parties from having encryption keys.
- encrypted section
	- contact id
	- introduction contacts message type
		- introduction id
		- list of temporary contacts
- IV

Each user validates this list against the original onion address list from the introduction request and ensures the request comes from the initiator. If the contents of intro request does not match the contacts contents the process is canceled by the user and a bad request is returned to the initiator. Users who have a valid list will continue to check the server for status. If not all users receive the list it can be resent or the process canceled

Once all users have accepted the initiator will begin to respond to introduction status requests with the "initiated" status. Once a user views this status they will begin the next step in the introduction process. Once all users have viewed the initiated command the initiator can consider the process completed and will ignore status requests.

Next, each user then goes down their received list of contacts sending introduction acknowledgement requests. Each request contains a randomly generated number. This is used to determine which user will create the encryption key and contact id for the contact. This serves no security purpose and is only for coordination.
- encrypted section
	- temp contact id
	- introduction acknowledgement message type
		- randomly generated number
- IV

The user with the highest number then sends a temporary contact update request, and updates their own contact to a permanent contact.
-  encrypted section
	- temp contact id
	- temporary contact update request message type
		- new contact id
		- new encryption key
- IV
The receiving user, if the request is valid, the updates and solidifies their contact.

The messaging protocol is fairly simple and uses the following format
- encrypted section
	- contact ID
	- message message type
		- optional group ID
		- message: text or files
- IV

Group chats can be created by sending all users a group chat request.
- encrypted section
	- contact id
	- group chat request message type
		- group chat id
		- list of participating users onion addresses
- IV
If not all users receive the request it can be resent.

Users can choose to accept or decline the group chat by sending a group chat response message. 
- encrypted section
	- contact id
	- group chat response message type
		- group chat id
		- accept or decline
- IV

Users can only accept a group chat if they have all the required onion contacts. If they don't have all the contacts users can send an introduction petition to the initiator.
- encrypted section
	- contact id
	- introduction petition message type
		- introduction id
		- list of user onion address to be introduced to
- IV

The initiator can choose to accept or decline by returning a introduction petition response message to decline.
- encrypted section
	- contact id
	- introduction petition declination message type
		- introduction id
- IV

or start the introduction process using the provided introduction id.

Once users have accepted the group chat they periodically check in with the initiator with “group chat status” requests, the initiator will return pending if not all users accepted, accepted if all users accepted or canceled if a user declined or if the process was canceled. Once all users have viewed a canceled or accepted the server will stop responding to requests. 
- encrypted section
	- Contact id
	- Group chat status request 
		- Group chat id
- IV

- encrypted section 
	- Contact id 
	- Group chat status response
		- Group chat id
		- Pending, cancelled or accepted 
- IV

After viewing an accepted status the users can begin using the group chat.

Pinging users can allow you check if a contact is able to receive messages. A ping has the following format.
- encrypted section 
	- contact id
	- Ping message type
		- Optional group id
- IV
A http 204 code is sent back to establish that the user is available.

To leave a group a user sends all users a notice of group exit message.
- encrypted section
	- Contact id
	- Notice of group exit message type 
		- Group ID
- IV

To add a user to a group, a group member must first send a group addition request to all perspective users and current users.
- encrypted section
	- contact id
	- group addition request
		- group id
		- group addition id
		- list of participants onion addresses and nick names
		- list of perspective members onion addresses and nick names
- IV

Users can choose to accept or decline the request with a group addition response
- encrypted section
	- contact id
	- group addition response
		- accept or deny
		- group id
		- addition id
- IV
Users can only accept if they have the contacts for all listed onion addresses. If they do not have the required contacts the can send a introduction petition message to the initiator.

After sending an accept response users will continuously monitor the addition by sending a group addition status requests.
- encrypted section
	- contact id
	- group addition request
		- group id
		- addition id
- IV

The initiator will respond with a group addition status response
- encrypted section
	- contact id
	- group addition response
		- cancelled, pending, or accepted

if any user declines the request the process is canceled and the initiator will respond to status requests until all participating users have seen a canceled status.

If accepted the initiator will display the accepted status until all participating users have seen it.

Once a user has viewed an accepted message they will add the users to their group chat participant list.
