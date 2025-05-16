import 'package:flutter/material.dart';

class SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Function(String) onSearch;
  final List<Widget> actions;
  final bool automaticallyImplyLeading;

  const SearchAppBar({
    Key? key,
    required this.title,
    required this.onSearch,
    this.actions = const [],
    this.automaticallyImplyLeading = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            showSearch(
              context: context,
              delegate: ProductSearchDelegate(onSearch: onSearch),
            );
          },
        ),
        ...actions,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class ProductSearchDelegate extends SearchDelegate<String> {
  final Function(String) onSearch;

  ProductSearchDelegate({required this.onSearch});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Container(); // Pas utilisé dans ce cas
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container(); // Pas utilisé dans ce cas
  }

  @override
  void showResults(BuildContext context) {
    onSearch(query);
    close(context, query);
  }
}