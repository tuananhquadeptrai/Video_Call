const { CommunicationIdentityClient } = require('@azure/communication-identity');

module.exports = async function (context, req) {
    context.log('Getting ACS token...');

    try {
        const { userId } = req.body;

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

        let user;
        let tokenResponse;

        if (userId) {
            // Use existing user ID
            user = { communicationUserId: userId };
            tokenResponse = await identityClient.getToken(user, ["voip"]);
        } else {
            // Create new user identity
            user = await identityClient.createUser();
            tokenResponse = await identityClient.getToken(user, ["voip"]);
        }

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
                data: {
                    token: tokenResponse.token,
                    expiresOn: tokenResponse.expiresOn,
                    user: user
                }
            }
        };

    } catch (error) {
        context.log.error('Error getting token:', error);
        
        context.res = {
            status: 500,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: {
                success: false,
                error: 'Failed to get token: ' + error.message
            }
        };
    }
};
