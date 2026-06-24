Deployment steps for Cloud Function (sendBranchNotification):

1. Install Firebase CLI and log in:

```bash
npm install -g firebase-tools
firebase login
```

2. From this `functions` folder install dependencies:

```bash
cd functions
npm install
```

3. Initialize functions (only if not already initialized) and deploy:

```bash
firebase init functions
# choose the existing Firebase project
# select JavaScript, not TypeScript (or adapt files accordingly)

firebase deploy --only functions:sendBranchNotification
```

This function listens to new documents in the `notifications` collection and sends an FCM
message to topic `branch_<branch>` (e.g. `branch_Python`). Ensure your Flutter app subscribes to
`branch_<studentBranch>` on login (already added in `auth_provider.dart`).
