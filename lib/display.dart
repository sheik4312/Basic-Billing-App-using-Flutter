import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventory/edititem.dart';
import 'drawer.dart';
import 'dart:io' show Platform;

class Display extends StatefulWidget {
  const Display({super.key});

  @override
  _DisplayState createState() => _DisplayState();
}

class _DisplayState extends State<Display> {
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  late Stream<QuerySnapshot> _itemStream;
  String _selectedCategory = '';
  List<String> _categories = [];
  String? _selectedItemId;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _itemStream =
        FirebaseFirestore.instance.collection('inventory').snapshots();
    _fetchCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color.fromARGB(255, 45, 44, 124),
        title: const Text(
          'Inventory',
          style: TextStyle(color: Colors.white),
        ),
      ),
      drawer: const CustomDrawer(
        initialSelectedIndex: 1,
      ),
      body: Platform.isWindows ? _buildWindowsLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Search items',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _performSearch(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => _showCategoryMenu(context),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder(
            stream: _itemStream,
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    return _buildListTiles(snapshot.data!.docs[index]);
                  },
                );
              }
              return const Center(child: Text('No items available'));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWindowsLayout() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Search items',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _performSearch(),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.filter_list),
                  label: const Text('Filter'),
                  onPressed: () => _showCategoryMenu(context),
                ),
                Expanded(
                  child: StreamBuilder(
                    stream: _itemStream,
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                        return ListView.builder(
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            return _buildListTiles(snapshot.data!.docs[index]);
                          },
                        );
                      }
                      return const Center(child: Text('No items available'));
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(
            color: Colors.grey[200],
            child: Center(
              child: _selectedItemId != null
                  ? EditItemScreen(
                      documentId: _selectedItemId!,
                      onBack: () {},
                    )
                  : Text(
                      'Detail View',
                      style: TextStyle(fontSize: 24, color: Colors.grey[700]),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListTiles(DocumentSnapshot document) {
    Map<String, dynamic>? data = document.data() as Map<String, dynamic>?;

    if (data == null || !data.containsKey('category')) {
      return const SizedBox();
    }

    String category = data['category'];

    if (_selectedCategory.isNotEmpty && _selectedCategory != category) {
      return const SizedBox();
    }

    return Column(
      children: [
        Container(
          color: Color.fromARGB(255, 255, 255, 255), // Set the background color
          child: ListTile(
            title: Text(data['item_name']),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Price: ${data['price']}'),
                Text('Category: $category'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.delete,
                    color: Color.fromARGB(230, 212, 65, 55),
                  ),
                  onPressed: () {
                    _showDeleteConfirmation(context, document);
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.edit,
                    color: Color.fromARGB(255, 54, 190, 134),
                  ),
                  onPressed: () {
                    if (Platform.isWindows) {
                      setState(() {
                        _selectedItemId = document.id;
                      });
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditItemScreen(
                            documentId: document.id,
                            onBack: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: Colors.grey),
      ],
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, DocumentSnapshot document) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content:
              Text('Are you sure you want to delete ${document['item_name']}?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                FirebaseFirestore.instance
                    .collection('inventory')
                    .doc(document.id)
                    .delete();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _performSearch() {
    String searchText = _searchController.text.trim().toLowerCase();
    setState(() {
      if (searchText.isNotEmpty) {
        _itemStream = FirebaseFirestore.instance
            .collection('inventory')
            .where('item_name', isGreaterThanOrEqualTo: searchText)
            .where('item_name', isLessThan: searchText + 'z')
            .snapshots();
      } else {
        _itemStream =
            FirebaseFirestore.instance.collection('inventory').snapshots();
      }
    });
  }

  Future<void> _fetchCategories() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('categories').get();
      setState(() {
        _categories = querySnapshot.docs
            .map((doc) =>
                (doc.data() as Map<String, dynamic>)['category_name'] as String)
            .toList();
      });
    } catch (error) {
      print('Error fetching categories: $error');
    }
  }

  void _filterByCategory(String selectedCategory) {
    setState(() {
      _selectedCategory = selectedCategory;
      _itemStream = FirebaseFirestore.instance
          .collection('inventory')
          .where('category', isEqualTo: selectedCategory)
          .snapshots();
    });
  }

  void _showCategoryMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          color: const Color.fromARGB(255, 15, 146, 247),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'Filters',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
              const Divider(color: Colors.white),
              ListTile(
                title: const Text('All', style: TextStyle(color: Colors.white)),
                onTap: () {
                  setState(() {
                    _selectedCategory = '';
                    _itemStream = FirebaseFirestore.instance
                        .collection('inventory')
                        .snapshots();
                  });
                  Navigator.pop(context);
                },
              ),
              const Divider(color: Colors.white),
              Expanded(
                child: ListView.builder(
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    return Column(
                      children: [
                        ListTile(
                          title: Text(_categories[index],
                              style: const TextStyle(color: Colors.white)),
                          onTap: () {
                            _filterByCategory(_categories[index]);
                            Navigator.pop(context);
                          },
                        ),
                        const Divider(color: Colors.white),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
