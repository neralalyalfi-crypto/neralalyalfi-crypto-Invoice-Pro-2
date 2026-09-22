import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
void main(){WidgetsFlutterBinding.ensureInitialized();runApp(const InvoicePro());}
class InvoicePro extends StatelessWidget{const InvoicePro({super.key});@override Widget build(BuildContext context)=>MaterialApp(debugShowCheckedModeBanner:false,title:'InvoicePro',theme:ThemeData(colorSchemeSeed:Colors.blue,useMaterial3:true),home:const DashboardScreen());}
