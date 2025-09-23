const { CommunicationIdentityClient } = require('@azure/communication-identity');

module.exports = async function (context, req) {
    context.log('Joining meeting...');

    try {
        const { meetingId, userName } = req.body;

        if (!meetingId || !userName) {
            context.res = {
                status: 400,
                body: { 
                    success: false,
                    error: 'Meeting ID and userName are required' 
                }
            };
            return;
        }

        // Validate meeting ID format
        const meetingIdRegex = /^\d{4}-\d{4}-\d{4}$/;
        if (!meetingIdRegex.test(meetingId)) {
            context.res = {
                status: 400,
                body: { 
                    success: false,
                    error: 'Invalid meeting ID format' 
                }
            };
            return;
        }

        // Get connection string from environment variables
        const connectionString = process.env.ACS_CONNECTION_STRING;
        
        if (!connectionString) {
            context.res = {
                status: 500,
                body: { 
                    success: false,
                    error: 'ACS connection string not configured' 
                }
            };
            return;
        }

        // Initialize Communication Identity Client
        const identityClient = new CommunicationIdentityClient(connectionString);

        // Create user identity for joining participant
        const user = await identityClient.createUser();
        
        // Get token for VoIP calling
        const tokenResponse = await identityClient.getToken(user, ["voip"]);

        // Meeting join response
        const joinInfo = {
            meetingId: meetingId,
            token: tokenResponse.token,
            expiresOn: tokenResponse.expiresOn,
            user: user,
            userName: userName,
            joinedAt: new Date().toISOString()
        };

        context.res = {
            status: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'POST, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type, Authorization'
            },
            body: {
                success: true,
                data: joinInfo
            }
        };

    } catch (error) {
        context.log.error('Error joining meeting:', error);
        
        context.res = {
            status: 500,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: {
                success: false,
                error: 'Failed to join meeting: ' + error.message
            }
        };
    }
};
