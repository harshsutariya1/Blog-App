import 'package:blog_app/users/services/auth_services.dart';
import 'package:blog_app/users/widgets/blog_tile.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:blog_app/constants/constants.dart';
import 'package:blog_app/models/user_provider.dart';
import 'package:blog_app/users/screens/home/drawer_screen.dart';
import 'package:blog_app/users/widgets/appbar_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'blog screens/create_blog_screen.dart';
import 'blog screens/blog_detail_screen.dart';
import 'package:blog_app/models/blog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends ConsumerState<HomeScreen> {
  final CollectionReference _blogs =
      FirebaseFirestore.instance.collection('blogs');
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late AuthService _authServices;

  Stream<List<Blog>> getBlogs() {
    return FirebaseFirestore.instance
        .collection('blogs')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Blog.fromDocument(doc)).toList();
    });
  }

  @override
  void initState() {
    _authServices = GetIt.instance.get<AuthService>();
    ref
        .read(userDataNotifierProvider.notifier)
        .fetchUserData(_authServices.user?.uid);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userDataNotifierProvider);
    print("profile pic url: ${userData.pfpURL}");

    return Scaffold(
      appBar: appBarWidget(context, userData, "Blogs"),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding:
                const EdgeInsets.only(left: 35, right: 35, top: 20, bottom: 20),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search Blogs',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.tune_sharp),
                  onPressed: () {
                    // Implement filter functionality
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: _blogs.snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final blogs = snapshot.data?.docs ?? [];

                // Filter blogs based on search query
                final filteredBlogs = blogs
                    .where((blog) {
                      final title =
                          blog['title']?.toString().toLowerCase().trim() ?? '';
                      return title.contains(_searchQuery.toLowerCase());
                    })
                    .map((doc) => Blog.fromDocument(doc))
                    .toList();

                if (filteredBlogs.isNotEmpty) {
                  return ListView.builder(
                    itemCount: filteredBlogs.length,
                    itemBuilder: (context, index) {
                      final blog = filteredBlogs[index];

                      return blogTile(
                        leadingImage: blog.imageUrl,
                        title: blog.title,
                        author: blog.author,
                        readingTime: blog.readingTime,
                        views: blog.views,
                        comments: blog.comments,
                        ontap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  BlogDetailScreen(blog: blog),
                            ),
                          );
                        },
                      );
                    },
                  );
                } else {
                  return Opacity(
                    opacity: 0.6,
                    child: Center(
                      child: Column(
                        children: [
                          const SizedBox(
                            height: 50,
                          ),
                          Image.asset(
                            "assets/images/3d-casual-life-question-mark-icon-1.png",
                            width: 200,
                            // color: ,
                          ),
                          const SizedBox(
                            height: 50,
                          ),
                          const Text('No blogs found'),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
      drawer: const DrawerScreen(selectedIndex: 0),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateBlogScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget listTile({required String title, required IconData icon}) {
    return Container(
      margin: const EdgeInsets.only(left: 20, bottom: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.horizontal(left: Radius.circular(50)),
      ),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Constants.drawerBackground),
        ),
        leading: Icon(
          icon,
          color: Constants.drawerBackground,
        ),
      ),
    );
  }
}
