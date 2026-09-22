import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/invoice.dart';

class DatabaseService {
  DatabaseService._();
  static final instance = DatabaseService._();
  Database? _db;

  Future<Database> get database async {
    _db ??= await openDatabase(join(await getDatabasesPath(), 'invoicepro.db'), version: 4,
      onCreate: (db, _) async {
        await db.execute('CREATE TABLE company (id INTEGER PRIMARY KEY, name TEXT NOT NULL, gstin TEXT, address TEXT, phone TEXT, email TEXT)');
        await db.insert('company', {'id':1,'name':'My Business','gstin':'','address':'','phone':'','email':''});
        await db.execute('CREATE TABLE customers (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, address TEXT, phone TEXT, email TEXT, gstin TEXT)');
        await db.execute('CREATE TABLE products (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, description TEXT, code TEXT, unit TEXT NOT NULL, price REAL NOT NULL, gst_rate REAL NOT NULL)');
        await db.execute('CREATE TABLE invoices (id INTEGER PRIMARY KEY AUTOINCREMENT, invoice_number TEXT NOT NULL, customer_name TEXT NOT NULL, customer_address TEXT, date TEXT NOT NULL, gst_rate REAL NOT NULL)');
        await db.execute('CREATE TABLE invoice_items (id INTEGER PRIMARY KEY AUTOINCREMENT, invoice_id INTEGER NOT NULL, description TEXT NOT NULL, quantity REAL NOT NULL, rate REAL NOT NULL, FOREIGN KEY(invoice_id) REFERENCES invoices(id) ON DELETE CASCADE)');
      },
      onUpgrade: (db, oldVersion, _) async {
        if (oldVersion < 2) {
          await db.execute('CREATE TABLE IF NOT EXISTS company (id INTEGER PRIMARY KEY, name TEXT NOT NULL, gstin TEXT, address TEXT, phone TEXT, email TEXT)');
          await db.insert('company', {'id':1,'name':'My Business','gstin':'','address':'','phone':'','email':''}, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        if (oldVersion < 3) await db.execute('CREATE TABLE IF NOT EXISTS customers (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, address TEXT, phone TEXT, email TEXT, gstin TEXT)');
        if (oldVersion < 4) await db.execute('CREATE TABLE IF NOT EXISTS products (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, description TEXT, code TEXT, unit TEXT NOT NULL, price REAL NOT NULL, gst_rate REAL NOT NULL)');
      },
    );
    return _db!;
  }

  Future<Map<String,dynamic>> getCompany() async { final db=await database; final rows=await db.query('company',where:'id=1',limit:1); return rows.first; }
  Future<void> saveCompany(Map<String,dynamic> company) async { final db=await database; await db.insert('company',{...company,'id':1},conflictAlgorithm:ConflictAlgorithm.replace); }
  Future<int> addCustomer(Map<String,dynamic> customer) async => (await database).insert('customers', customer);
  Future<List<Map<String,dynamic>>> getCustomers({String query=''}) async {
    final db=await database;
    if (query.trim().isEmpty) return db.query('customers',orderBy:'name COLLATE NOCASE');
    return db.query('customers',where:'name LIKE ? OR phone LIKE ? OR gstin LIKE ?',whereArgs:['%$query%','%$query%','%$query%'],orderBy:'name COLLATE NOCASE');
  }
  Future<void> updateCustomer(int id, Map<String,dynamic> customer) async => (await database).update('customers',customer,where:'id=?',whereArgs:[id]);
  Future<void> deleteCustomer(int id) async => (await database).delete('customers',where:'id=?',whereArgs:[id]);
  Future<int> addProduct(Map<String,dynamic> product) async => (await database).insert('products', product);
  Future<List<Map<String,dynamic>>> getProducts({String query=''}) async {
    final db=await database;
    if (query.trim().isEmpty) return db.query('products',orderBy:'name COLLATE NOCASE');
    return db.query('products',where:'name LIKE ? OR code LIKE ? OR description LIKE ?',whereArgs:['%$query%','%$query%','%$query%'],orderBy:'name COLLATE NOCASE');
  }
  Future<void> updateProduct(int id, Map<String,dynamic> product) async => (await database).update('products',product,where:'id=?',whereArgs:[id]);
  Future<void> deleteProduct(int id) async => (await database).delete('products',where:'id=?',whereArgs:[id]);
  Future<int> insertInvoice(Invoice invoice) async {
    final db=await database;
    return db.transaction((txn) async {
      final id=await txn.insert('invoices',invoice.toMap()..remove('id'));
      for(final item in invoice.items) await txn.insert('invoice_items',item.toMap(id)..remove('id'));
      return id;
    });
  }
  Future<void> deleteInvoice(int id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('invoice_items', where: 'invoice_id=?', whereArgs: [id]);
      await txn.delete('invoices', where: 'id=?', whereArgs: [id]);
    });
  }

  Future<List<Invoice>> getInvoices() async {
    final db=await database; final rows=await db.query('invoices',orderBy:'date DESC,id DESC'); final result=<Invoice>[];
    for(final row in rows){final items=await db.query('invoice_items',where:'invoice_id=?',whereArgs:[row['id']]);result.add(Invoice.fromMap(row,items.map(InvoiceItem.fromMap).toList()));}
    return result;
  }
}