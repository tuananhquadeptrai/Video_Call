const { CommunicationIdentityClient } = require('@azure/communication-identity');
const { v4: uuidv4 } = require('uuid');

module.exports = async function (context, req) {
    context.log('Creating new meeting...');

    try {
        // Get connection string from environment variables
        const connectionString = process.env.ACS_CONNECTION_STRING;
        
        if (!connectionString) {
            context.res = {
                status: 500,
                body: { error: 'ACS connection string not configured' }
            };
            return;
        }

        // Initialize Communication Identity Client
        const identityClient = new CommunicationIdentityClient(connectionString);

        // Create user identity
        const user = await identityClient.createUser();
        
        // Get token for VoIP calling
        const tokenResponse = await identityClient.getToken(user, ["voip"]);

        // Generate meeting ID
        const meetingId = generateMeetingId();

        // Meeting response
        const meetingInfo = {
            meetingId: meetingId,
            token: tokenResponse.token,
            expiresOn: tokenResponse.expiresOn,
            user: user,
            title: req.body?.title || 'Video Call Meeting',
            createdAt: new Date().toISOString(),
            maxParticipants: req.body?.maxParticipants || 50,
            recordingEnabled: req.body?.recordingEnabled || false
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
                data: meetingInfo
            }
        };

    } catch (error) {
        context.log.error('Error creating meeting:', error);
        
        context.res = {
            status: 500,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: {
                success: false,
                error: 'Failed to create meeting: ' + error.message
            }
        };
    }
};

function generateMeetingId() {
    // Generate meeting ID in format: XXXX-XXXX-XXXX
    const timestamp = Date.now().toString();
    const randomPart = Math.random().toString(36).substring(2, 8).toUpperCase();
    const id = (timestamp.slice(-8) + randomPart).substring(0, 12);
    return `${id.substring(0, 4)}-${id.substring(4, 8)}-${id.substring(8, 12)}`;
}
