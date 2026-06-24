const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

exports.sendBranchNotification = functions.firestore
  .document('notifications/{docId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    if (!data) return null;
    const branch = data.branch || 'all';
    const topic = `branch_${branch}`;

    const message = {
      topic: topic,
      notification: {
        title: data.title || 'New Content',
        body: data.message || '',
      },
      data: {
        branch: branch,
        docId: context.params.docId || ''
      }
    };

    try {
      const response = await admin.messaging().send(message);
      console.log('Sent message:', response);
      return response;
    } catch (err) {
      console.error('Error sending message:', err);
      return null;
    }
  });
