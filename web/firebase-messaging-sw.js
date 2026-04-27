
// Import Firebase scripts
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

// Real config from firebase_options.dart
const firebaseConfig = {
  apiKey: "AIzaSyBGKca509XEcmigLVm4QMNefURsHDllWQw",
  authDomain: "od-management-59dbc.firebaseapp.com",
  projectId: "od-management-59dbc",
  storageBucket: "od-management-59dbc.firebasestorage.app",
  messagingSenderId: "523686545504",
  appId: "1:523686545504:web:99e94a4a11377c892a5b05"
};

// Initialize Firebase
firebase.initializeApp(firebaseConfig);

// Initialize messaging
const messaging = firebase.messaging();

// Handle background notifications
messaging.onBackgroundMessage(function(payload) {
  console.log("\uD83D\uDCE9 Background message received:", payload);

  const notificationTitle = payload.notification.title || "New Notification";
  const notificationOptions = {
    body: payload.notification.body || "",
    icon: "/icons/Icon-192.png"
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
