import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/user_service.dart';

class AdminUserScreen extends StatefulWidget {
  const AdminUserScreen({super.key});

  @override
  State<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 🔥 STREAM REALTIME
  Stream<QuerySnapshot> getUsers() {
    return _db.collection("users").snapshots();
  }

  /// 🔥 UPDATE ROLE
  Future<void> toggleAdmin(String uid, bool currentStatus) async {
    await _db.collection("users").doc(uid).update({
      "isAdmin": !currentStatus,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = UserService.instance.isSuperAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý người dùng"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final data =
                  users[index].data() as Map<String, dynamic>;

              final uid = users[index].id;
              final email = data["email"] ?? "";
              final isAdmin = data["isAdmin"] ?? false;

              return Card(
                margin: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        isAdmin ? Colors.red : Colors.grey,
                    child: Icon(
                      isAdmin
                          ? Icons.admin_panel_settings
                          : Icons.person,
                      color: Colors.white,
                    ),
                  ),

                  title: Text(email),

                  subtitle: Text(
                    isAdmin ? "Admin" : "User",
                    style: TextStyle(
                      color: isAdmin ? Colors.red : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  /// 🔥 NÚT PHÂN QUYỀN
                  trailing: isSuperAdmin
                      ? ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isAdmin ? Colors.grey : Colors.blue,
                          ),
                          onPressed: () async {
                            await toggleAdmin(uid, isAdmin);

                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                content: Text(
                                  isAdmin
                                      ? "Đã thu hồi quyền admin"
                                      : "Đã cấp quyền admin",
                                ),
                              ),
                            );
                          },
                          child: Text(
                            isAdmin ? "Huỷ quyền" : "Cấp quyền",
                          ),
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}