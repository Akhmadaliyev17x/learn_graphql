import 'package:flutter/material.dart';
import 'package:graphql/client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Home(), debugShowCheckedModeBanner: false);
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isLoading = false;
  List<Product> data = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void fetchData() async {
    isLoading = true;
    setState(() {});
    final result = await GQLService.query(
      GQLService.queryOptionsGetAllProducts,
    );
    isLoading = false;
    if (result != null) {
      data = GQLService.parseProducts(result);
      setState(() {});
    }
  }

  void filterData(String filter) async {
    isLoading = true;
    setState(() {});
    final result = await GQLService.query(
      GQLService.queryOptionsFilterProducts(filter),
    );
    isLoading = false;
    if (result != null) {
      data = GQLService.parseProducts(result);
      setState(() {});
    }
  }

  Future<void> deleteData(String id) async {
    final result = await GQLService.mutate(
      GQLService.queryOptionsDeleteProduct(id),
    );
    if (result == null) {
      print("Mahsulot o'chmadi!");
    } else {
      print("O'chirildi: $result");
      fetchData();
    }
  }

  Future<String?> showCustomBottomSheet() async {
    final result = await showModalBottomSheet(
      context: context,
      builder: (_) {
        num minPrice = 0;
        num maxPrice = 0;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Filter by Price",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextField(
                decoration: const InputDecoration(labelText: "Minimum Price"),
                keyboardType: TextInputType.number,
                onChanged: (value) => minPrice = num.tryParse(value) ?? 0,
              ),
              TextField(
                decoration: const InputDecoration(labelText: "Maximum Price"),
                keyboardType: TextInputType.number,
                onChanged: (value) => maxPrice = num.tryParse(value) ?? 0,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, {'min': minPrice, 'max': maxPrice});
                },
                child: const Text("Apply Filter"),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      return "price_min: ${result['min']}, price_max: ${result['max']}";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mahsulotlar"),
        actions: [
          IconButton(
            onPressed: () async {
              final result = await showCustomBottomSheet();
              if (result != null) {
                filterData(result);
              }
            },
            icon: Icon(Icons.filter_alt),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (context, index) {
              return Dismissible(
                onDismissed: (direction) async {
                  await deleteData(data[index].id);
                  data.removeAt(index);
                  setState(() {});
                },

                key: ValueKey(data[index].id),
                child: Card(
                  child: ListTile(
                    leading: Image.network(
                      data[index].images.first,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => ColoredBox(
                        color:
                            Colors.primaries[index % Colors.primaries.length],
                        child: const SizedBox(width: 50, height: 50),
                      ),
                    ),
                    title: Text(data[index].title),
                    subtitle: Text(
                      data[index].description,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      "${data[index].price.toStringAsFixed(1)}\$",
                      style: TextTheme.of(context).bodyMedium,
                    ),
                  ),
                ),
              );
            },
          ),
          isLoading ? CircularProgressIndicator() : SizedBox.shrink(),
        ],
      ),
    );
  }
}

// GraphQL servis
sealed class GQLService {
  static final _httpLink = HttpLink('https://api.escuelajs.co/graphql');

  static final GraphQLClient client = GraphQLClient(
    cache: GraphQLCache(),
    link: _httpLink,
  );

  static Future<Map<String, dynamic>?> query(QueryOptions options) async {
    final result = await client.query(options);
    if (result.hasException) {
      print("Query xatosi: ${result.exception.toString()}");
      return null;
    } else {
      return result.data;
    }
  }

  static Future<Map<String, dynamic>?> mutate(MutationOptions options) async {
    final result = await client.mutate(options);
    if (result.hasException) {
      print("Mutation xatosi: ${result.exception.toString()}");
      return null;
    } else {
      return result.data;
    }
  }

  // --- GraphQL so‘rovlar
  static const _queryGetAllProducts = """
query {
  products {
    id
    title
    price
    description
    images
    category {
      id
      name
      image
    }
  }
}
""";

  static String _query(String filter) =>
      """
query {
  products($filter) {
    id
    title
    price
    description
    images
    category {
      id
      name
      image
    }
  }
}
""";

  static String queryDelete(String id) =>
      """
mutation {
  deleteProduct(id: "$id")
}
""";

  static final queryOptionsGetAllProducts = QueryOptions(
    document: gql(_queryGetAllProducts),
    cacheRereadPolicy: CacheRereadPolicy.ignoreAll,
    fetchPolicy: FetchPolicy.networkOnly,
  );

  static QueryOptions queryOptionsFilterProducts(String filter) => QueryOptions(
    document: gql(_query(filter)),
    cacheRereadPolicy: CacheRereadPolicy.ignoreAll,
    fetchPolicy: FetchPolicy.networkOnly,
  );

  static MutationOptions queryOptionsDeleteProduct(String id) =>
      MutationOptions(document: gql(queryDelete(id)));

  static List<Product> parseProducts(Map<String, Object?> json) {
    return (json["products"] as List).map((e) => Product.fromJson(e)).toList();
  }
}

// Model: Category
class Category {
  final String id;
  final String name;
  final String image;

  const Category({required this.id, required this.name, required this.image});

  factory Category.fromJson(Map<String, Object?> json) {
    return Category(
      id: json["id"] as String,
      name: json["name"] as String,
      image: json["image"] as String,
    );
  }
}

// Model: Product
class Product {
  final String id;
  final String title;
  final num price;
  final String description;
  final List<String> images;
  final Category category;

  const Product({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.images,
    required this.category,
  });

  factory Product.fromJson(Map<String, Object?> json) {
    return Product(
      id: json["id"] as String,
      title: json["title"] as String,
      price: json['price'] as num,
      description: json["description"] as String,
      images: List<String>.from(json["images"] as List),
      category: Category.fromJson(json["category"] as Map<String, Object?>),
    );
  }
}
