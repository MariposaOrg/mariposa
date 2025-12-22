#action #action #mariposa 
#Discovery

# Notes
- AES-GCM mode
- Only authentication needed is that the person you are talking to hasn't changed. This could occur if someone over took another hash.
- RSA signatures? is not quantum safe
- what even is post quantum: AES 256. Symmetric keys are safe, don't need a salt.
- Forward secrecy [[What is perfect forward secrecy or PFS]] Need to workshop message sending ratcheting mechanism. Key in the message? seems cleanest 
	- bad key messages don't move forward from receiver
	- no way to tell if sender got 200
	- only 1 unconfirmed message per chat
# Statement of action
Create a protocol that allows users to send message back and forth over http
# Statement of inputs

# Statement of specifications
- Should be quantum secure
- Once a conversation is started you should be able to verify the person. you are talking to has not changed.
- Should work with group conversations.
- Work with files
- Fault tolerant
- cannot rely on HTTP status codes
- good User feedback
- Secure against bit flipping attacks
- Forward secrecy

# Statement of Design
## Output: The mariposa protocol

Mariposa is a peer to peer encrypted messaging protocol built on HTTPS between TOR hidden services. Communication takes place over two main activities: contact and messaging. Contact is the process in which users are able to create contacts for other users. It is designed to take place in person. Messaging is the process in which users communicate. Users can send messages to single users or group chats.

Encryption takes place using AES-GCM mode with 256 bit keys. AES is used with GCM mode to prevent bit flipping attacks. Symmetric encryption is used to hedge against the rise of a security significant quantum system.

Exact data transfer formats are omitted to allow for flexibility. However, for this specification, all data transfer can be assumed to take place over HTTPS.

A Contact stores all the information needed to message a user. It has the following form.
- contact id, a unique hash
- onion address for contact
- 256 bit encryption key for messages
- contact nickname, plain text

The basic protocol structure consists of four sections.
- an encrypted section
	- sender contact id
	- A type of message 
- Initialization vector 

The recipient iterates their contact list using each respective key to attempt decryption. Once a message is decrypted the user can verify that the sender contact Id in the message is the same as the one associated with the decryption key.

## Contact
Contact takes place in person as Mariposa has no central server for authentication. The method is as follows. First, user one creates a temporary contact and shares the following information with the user two.
- contact id - a unique 256 bit random hash, kept secret, between users.
- onion address - the link the tor address for user one
- an encryption key - a 256 encryption key

This information can be shared using a QR code or passed over Bluetooth.

Using this, user two creates a contact, and sends a "initial contact" message to user one’s onion address. The contact message takes the following structure
- encrypted section
	- contact id - ID received from user one
	- initial contact message type
		- senders onion address
- IV
## Messaging 
the message protocol is simple.
- encrypted section
	- contact id
	- message message type
		- optional group id
		- message: text or files
- IV
#### Group chats
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

Users can only accept a group chat if they have all the required onion contacts. 

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

To leave a group a user sends all users a notice of group exit message.
- encrypted section
	- Contact id
	- Notice of group exit message type 
		- Group ID
- IV

To add a user to a group, a group member must first send a group addition request to all prospective users and current users.
- encrypted section
	- contact id
	- group addition request message type
		- group id
		- group addition id
		- list of participants onion addresses and nick names
		- list of prospective members onion addresses and nick names
- IV

Users can choose to accept or decline the request with a group addition response
- encrypted section
	- contact id
	- group addition response message type
		- accept or deny
		- group id
		- addition id
- IV
Users can only accept if they have the contacts for all listed onion addresses.

After sending an accept response users will continuously monitor the addition by sending a group addition status requests.
- encrypted section
	- contact id
	- group addition request message type
		- group id
		- addition id
- IV

The initiator will respond with a group addition status response
- encrypted section
	- contact id
	- group addition response message type
		- cancelled, pending, or accepted

if any user declines the request the process is canceled and the initiator will respond to status requests until all participating users have seen a canceled status.

If accepted the initiator will display the accepted status until all participating users have seen it.

Once a user has viewed an accepted message they will add the users to their group chat participant list.

To message in a group chat a user will send a standard message but with a group ID to all contacts that are listed as apart of their group, separately 

## Utility
Pinging users can allow you check if a contact is able to receive messages. A ping has the following format.
- encrypted section 
	- contact id
	- Ping message type
		- Optional group id
- IV
A http 204 code is sent back to establish that the user is available.

This protocol should be stored in the /docs directory of mariposa






