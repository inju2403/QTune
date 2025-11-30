/**
 * Script to enable Firestore API using Firebase Admin SDK
 */
const { exec } = require('child_process');
const util = require('util');
const execAsync = util.promisify(exec);

const PROJECT_ID = 'qtune-a7668';

async function enableFirestoreAPI() {
  console.log('🔧 Enabling Firestore API for project:', PROJECT_ID);

  try {
    // Use gcloud command if available
    const { stdout, stderr } = await execAsync(
      `gcloud services enable firestore.googleapis.com --project=${PROJECT_ID}`
    );

    if (stderr && !stderr.includes('already enabled')) {
      console.error('❌ Error:', stderr);
      return false;
    }

    console.log('✅ Firestore API enabled successfully!');
    console.log(stdout);
    return true;
  } catch (error) {
    console.error('❌ Failed to enable Firestore API:', error.message);
    console.log('\n📝 Please enable Firestore manually:');
    console.log(`   1. Open: https://console.firebase.google.com/project/${PROJECT_ID}/firestore`);
    console.log('   2. Click "Create Database"');
    console.log('   3. Select location: us-central');
    console.log('   4. Choose "Start in production mode"');
    return false;
  }
}

enableFirestoreAPI().then(success => {
  process.exit(success ? 0 : 1);
});
