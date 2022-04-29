import 'package:flutter/material.dart';
import 'package:flutter_course/models/post_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(Home());
}

class Home extends StatelessWidget {
  Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<PostModel> lstPosts = [];
  int page = 1;
  int limit = 10;
  bool isLoading = false;
  bool isLastPage = false;
  final ScrollController _scrollController = ScrollController();
  late Future<List<PostModel>?> _future = fetchPost(page: page, limit: limit);
  @override
  void initState() {
    // _future = fetchPost();
    pagination();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Home"),
        ),
        body: FutureBuilder(
          future: _future,
          builder:
              (BuildContext context, AsyncSnapshot<List<PostModel>?> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError) {
                return const  Center(
                  child: Text('Server Error'),
                );
              } else {
                if (snapshot.data != null && snapshot.data!.isNotEmpty) {
                  return Column(
                    children: [
                      Expanded(
                          flex: 9,
                          child: ListView.builder(
                            key: const PageStorageKey('home'),
                            controller: _scrollController,
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.all(12),
                                child: Card(
                                  child: ListTile(
                                    title: Text(
                                        snapshot.data![index].title.toString()),
                                    leading: Text(
                                        snapshot.data![index].id.toString()),
                                  ),
                                ),
                              );
                            },
                          )),
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: isLastPage && !isLoading
                              ? const Text('No more data')
                              : Container(),
                        ),
                      ),
                      Center(
                        child: isLoading ? const Text('Loading') : Container(),
                      ),
                    ],
                  );
                } else {
                  return const Text('No data');
                }
              }
            } else {
              return  const Center(
                child: Text('Error'),
              );
            }
          },
          // future: fetchPost(),
        ));
  }

  Future<List<PostModel>?> fetchPost({int? page, int? limit}) async {
    setState(() {
      isLoading = true;
    });
    try {
      var url =
          Uri.parse('http://localhost:3000/posts?_limit=$limit&_page=$page');
      final res = await http.get(url);
      // print('state code ${res.statusCode}');
      if (res.statusCode == 200) {
        int totalRecord = int.parse(res.headers['x-total-count']!);
        // print('total record ${totalRecord}');
        // print('lst length ${lstPosts.length}');
        if (lstPosts.length >= totalRecord) {
          isLastPage = true;
        }
        // print('total recors ${res.headers['x-total-count']}');

        /// convert string to json object
        List result = jsonDecode(res.body);
        // print('result $result');
        lstPosts.addAll(result.map((e) => PostModel.fromJson(e)).toList());
        setState(() {
          isLoading = false;
        });
        return lstPosts;
      } else {
        print('debug error fetch post error.');
        setState(() {
          isLoading = false;
        });
        return null;
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('error $e');
      return null;
    }
  }

  getMore({bool isRefresh = false}) async {
    if (isRefresh) {
      page = 1;
    }
    if (!isRefresh) {
      page++;
    }

    _future = fetchPost(page: page, limit: limit);
  }

  pagination() async {

    _scrollController.addListener(() {
      if (_scrollController.position.maxScrollExtent ==
              _scrollController.position.pixels &&
          !isLoading) {
        setState(() {
          getMore(isRefresh: false);
        });
      }
    });
  }
}
