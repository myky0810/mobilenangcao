# 🔐 Firebase Security Rules - Human Handoff System

## 📋 **Firestore Rules**

Thêm các rules sau vào `firestore.rules`:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ============================================
    // ADMIN NOTIFICATIONS
    // ============================================
    match /admin_notifications/{notificationId} {
      // Allow AI to create notifications
      allow create: if true;
      
      // Only admin can read/update/delete
      allow read, update, delete: if request.auth != null && 
                                     request.auth.token.role == 'admin';
    }
    
    // ============================================
    // CHATS
    // ============================================
    match /chats/{chatId} {
      // Allow users to read their own chat
      allow read: if request.auth != null && 
                     (request.auth.uid == chatId || 
                      request.auth.token.role == 'admin');
      
      // Allow AI/User to create/update chat
      allow create, update: if true;
      
      // Only admin can delete
      allow delete: if request.auth != null && 
                       request.auth.token.role == 'admin';
      
      // Chat messages subcollection
      match /messages/{messageId} {
        // Anyone can read messages in their chat
        allow read: if true;
        
        // Anyone can create messages
        allow create: if true;
        
        // Only creator or admin can update/delete
        allow update, delete: if request.auth != null && 
                                 request.auth.token.role == 'admin';
      }
    }
    
    // ============================================
    // AI FEEDBACK
    // ============================================
    match /ai_feedback/{feedbackId} {
      // Anyone can create feedback
      allow create: if true;
      
      // Only admin can read all feedback
      allow read: if request.auth != null && 
                     request.auth.token.role == 'admin';
    }
    
    // ============================================
    // USERS
    // ============================================
    match /users/{userId} {
      // Users can read their own data
      allow read: if request.auth != null && 
                     (request.auth.uid == userId || 
                      request.auth.token.role == 'admin');
      
      // Users can update their own data
      allow update: if request.auth != null && 
                       request.auth.uid == userId;
      
      // Admin can do everything
      allow read, write: if request.auth != null && 
                            request.auth.token.role == 'admin';
    }
  }
}
```

---

## 🔑 **Admin Role Setup**

### **1. Tạo Custom Claims cho Admin**

Sử dụng Firebase Admin SDK hoặc Cloud Functions:

```javascript
// Cloud Function example
const admin = require('firebase-admin');

exports.setAdminRole = functions.https.onCall(async (data, context) => {
  // Verify caller is already admin or use secret key
  
  const uid = data.uid;
  
  await admin.auth().setCustomUserClaims(uid, {
    role: 'admin'
  });
  
  return {
    success: true,
    message: `Admin role granted to ${uid}`
  };
});
```

### **2. Kiểm Tra Admin Role trong Flutter**

```dart
Future<bool> isAdmin() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;
  
  final idTokenResult = await user.getIdTokenResult();
  return idTokenResult.claims?['role'] == 'admin';
}
```

---

## 🧪 **Testing Rules**

### **Test 1: Create Notification (Success)**
```javascript
// As unauthenticated user (AI)
firestore.collection('admin_notifications').add({
  type: 'human_handoff_request',
  chatId: 'test123',
  // ... other fields
});
// Expected: SUCCESS
```

### **Test 2: Read Notification (Admin Only)**
```javascript
// As regular user
firestore.collection('admin_notifications').get();
// Expected: PERMISSION_DENIED

// As admin
firestore.collection('admin_notifications').get();
// Expected: SUCCESS
```

### **Test 3: Update Chat Status (Admin)**
```javascript
// As admin
firestore.collection('chats').doc('test123').update({
  status: 'human',
  assignedStaff: 'Staff Name'
});
// Expected: SUCCESS
```

---

## 📊 **Firebase Indexes**

Thêm các indexes sau vào `firestore.indexes.json`:

```json
{
  "indexes": [
    {
      "collectionGroup": "admin_notifications",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "admin_notifications",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "type",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "read",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "messages",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "createdAt",
          "order": "ASCENDING"
        }
      ]
    }
  ]
}
```

---

## 🚨 **Security Best Practices**

### ✅ **DO:**
- ✅ Always validate admin role on server-side
- ✅ Use custom claims for role-based access
- ✅ Log all admin actions
- ✅ Rate limit notification creation
- ✅ Validate data before writing

### ❌ **DON'T:**
- ❌ Store admin password in client code
- ❌ Allow public write to admin_notifications
- ❌ Trust client-side role checks alone
- ❌ Skip data validation

---

## 📦 **Deployment**

### **1. Deploy Rules**
```bash
firebase deploy --only firestore:rules
```

### **2. Deploy Indexes**
```bash
firebase deploy --only firestore:indexes
```

### **3. Verify**
```bash
firebase firestore:indexes
```

---

**Tài liệu được tạo tự động**
**Ngày: 31/03/2026**
