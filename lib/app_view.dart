import 'package:expense_repository/expense_repository.dart';
import 'package:expenses_tracker/screens/home/blocs/get_expenses_bloc/get_expenses_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth/bloc/auth_bloc.dart';
import 'auth/firebase_auth_provider.dart';
import 'main.dart';
import 'screens/home/views/home_screen.dart';


import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MyAppView extends StatelessWidget {
  const MyAppView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(

      providers: [
        BlocProvider<GetExpensesBloc>(
          create: (context) => GetExpensesBloc(
            FirebaseExpenseRepo(),
          )..add(GetExpenses()),
        ),
        BlocProvider<GetIncomesBloc>(
          create: (context) => GetIncomesBloc(
            FirebaseExpenseRepo2(),
          )..add(GetIncomes()),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        title: "Expense Tracker",
        theme: ThemeData(
          colorScheme: ColorScheme.light(
            background: Colors.grey.shade100,
            onBackground: Colors.black,
            primary: const Color(0xFF00B2E7),
            secondary: const Color(0xFFE064F7),
            tertiary: const Color(0xFFFF8D6C),
            outline: Colors.grey,
          ),
        ),
        home: BlocProvider(
          create: (context) => AuthBloc(
            FirebaseAuthProvider(),
          ),
          child: const HomePage(),
        ),
      ),
    );
  }
}


/*class MyAppView extends StatelessWidget {
  const MyAppView({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Expense Tracker",
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          background: Colors.grey.shade100,
          onBackground: Colors.black,
          primary: const Color(0xFF00B2E7),
          secondary: const Color(0xFFE064F7),
          tertiary: const Color(0xFFFF8D6C),
          outline: Colors.grey,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => BlocProvider(
          create: (context) => GetExpensesBloc(
            FirebaseExpenseRepo(),
          )..add(GetExpenses()),
          child: HomeScreen(),
        ),
        '/incomes': (context) => BlocProvider(
          create: (context) => GetIncomesBloc(
            FirebaseExpenseRepo2(),
          )..add(GetIncomes()),
          child: HomeScreen(), // You might want to use a different screen for incomes
        ),
      },
    );
  }
}

 */
