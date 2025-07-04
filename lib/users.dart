import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:graphql/client.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
      theme: ThemeData(
        colorSchemeSeed: Colors.indigoAccent
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isLoading = false;
  List<User> data = [];
  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void fetchData() async {
    isLoading = true;
    setState(() {});
    final result = await GQLService.query(
      GQLService.queryOptionsGetAllUsers,
    );
    isLoading = false;
    if (result != null) {
      data = GQLService.parseUsers(result);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Users"),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          ListView.builder(
            padding: EdgeInsets.all(20),
            itemCount: data.length,
            itemBuilder: (context , index){
              User user = data[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(backgroundImage: NetworkImage(user.avatar),),
                  title: Text(user.name),
                  subtitle: Text(user.email),
                ),
              );
            },
          ),
          isLoading? Scaffold(
            backgroundColor: Colors.black12,
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ) : SizedBox.shrink()
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: ()async{
        User? user = await Navigator.push(context, CupertinoPageRoute(builder: (context) => CreateUserPage()));
        if(user!= null){
         final result = await GQLService.mutate(GQLService.queryOptionsCreateUser(user)) ;
         print('\n\n\n\nResult\n');
         print(result);
         fetchData();
        }
      } , child: Icon(Icons.add),),
    );
  }
}


class CreateUserPage extends StatefulWidget {
  const CreateUserPage({super.key});

  @override
  State<CreateUserPage> createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _avatarController = TextEditingController();

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.pop(context,
          User(id: "", name: _nameController.text, email: _emailController.text, avatar: _avatarController.text , password: _passwordController.text)
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create User")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                (value == null || value.isEmpty) ? 'Please enter name' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) =>
                (value == null || value.isEmpty) ? 'Please enter email' : null,
              ),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (value) =>
                (value == null || value.isEmpty) ? 'Please enter password' : null,
              ),
              TextFormField(
                controller: _avatarController,
                decoration: const InputDecoration(labelText: 'Avatar URL'),
                validator: (value) =>
                (value == null || value.isEmpty) ? 'Please enter avatar url' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: const Text("Create"),
              )
            ],
          ),
        ),
      ),
    );
  }
}


sealed class GQLService {
  static final _httpLink = HttpLink('https://api.escuelajs.co/graphql');

  static final client = GraphQLClient(link: _httpLink, cache: GraphQLCache());

  static Future<Map<String, dynamic>?> mutate(MutationOptions options) async {
    final result = await client.mutate(options);
    if (result.hasException) {
      print("Mutation xatosi: ${result.exception.toString()}");
      return null;
    } else {
      return result.data;
    }
  }

  static Future<Map<String, dynamic>?> query(QueryOptions options) async {
    final result = await client.query(options);
    if (result.hasException) {
      print("Query xatosi: ${result.exception.toString()}");
      return null;
    } else {
      return result.data;
    }
  }

  static const _queryGetAllUsers = """
query {
  users {
    id
    name
    email
    password
    avatar
  }
}
""";

  static String _queryCreateUser(User user) =>
      """
mutation {
  addUser(
    data: {
      name: "${user.name}"
      email: "${user.email}"
      password: "${user.password}"
      avatar: "${user.avatar}"
    }
  ) {
    id
    name
    avatar
  }
}
""";


  static final queryOptionsGetAllUsers = QueryOptions(
    document: gql(_queryGetAllUsers),
    cacheRereadPolicy: CacheRereadPolicy.ignoreAll,
    fetchPolicy: FetchPolicy.networkOnly,
  );
  static MutationOptions queryOptionsCreateUser(User user) =>
      MutationOptions(document: gql(_queryCreateUser(user)));

  static List<User> parseUsers(Map<String, Object?> json) {
    return (json["users"] as List)
        .map((e) => User.fromJson(e as Map<String, dynamic>))
        .toList();
  }


}

class User {
  String id;
  String name;
  String email;
  String? password;
  String avatar;

//<editor-fold desc="Data Methods">


  User({
    required this.id,
    required this.name,
    required this.email,
    this.password,
    required this.avatar,
  });


  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          (other is User &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              name == other.name &&
              email == other.email &&
              password == other.password &&
              avatar == other.avatar
          );


  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      email.hashCode ^
      password.hashCode ^
      avatar.hashCode;


  @override
  String toString() {
    return 'User{' +
        ' id: $id,' +
        ' name: $name,' +
        ' email: $email,' +
        ' password: $password,' +
        ' avatar: $avatar,' +
        '}';
  }


  User copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    String? avatar,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      avatar: avatar ?? this.avatar,
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': this.id,
      'name': this.name,
      'email': this.email,
      'password': this.password,
      'avatar': this.avatar,
    };
  }

  factory User.fromJson(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      avatar: map['avatar'] as String,
    );
  }


//</editor-fold>
}
