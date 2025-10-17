// lib/main.dart
import 'package:flutter/material.dart';

void main() => runApp(const LaundryApp());

class LaundryApp extends StatelessWidget {
  const LaundryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '세탁수거배달',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (_) => const RoleGateScreen(),
        '/customer/home': (_) => const CustomerHomeScreen(),
        '/operator/dashboard': (_) => const OperatorDashboardScreen(),
        '/order/detail': (_) => const OrderDetailScreen(),
        '/order/create': (_) => const OrderCreateScreen(),
      },
    );
  }
}

enum OrderStatus { pending, approved, collected, washing, delivering, done }
enum PaymentStatus { unpaid, partial, paid }

class OrderItem {
  final String name;
  final int qty;
  final int price;
  const OrderItem({required this.name, required this.qty, required this.price});
}

class OrderModel {
  final String id;
  final String customerName;
  final String address;
  final DateTime requestedAt;
  OrderStatus status;
  PaymentStatus payment;
  final List<OrderItem> items;

  OrderModel({
    required this.id,
    required this.customerName,
    required this.address,
    required this.requestedAt,
    this.status = OrderStatus.pending,
    this.payment = PaymentStatus.unpaid,
    this.items = const [],
  });

  int get amount => items.fold(0, (s, it) => s + it.price * it.qty);
}

class AppStore extends ChangeNotifier {
  final List<OrderModel> _orders = [
    OrderModel(
      id: 'A2025-001',
      customerName: '김고객',
      address: '성남시 분당구 수내동',
      requestedAt: DateTime.now(),
      items: [OrderItem(name: '와이셔츠', qty: 3, price: 1900)],
    ),
    OrderModel(
      id: 'A2025-002',
      customerName: '박고객',
      address: '경기 광주시 오포읍',
      requestedAt: DateTime.now().add(const Duration(minutes: 30)),
      items: [OrderItem(name: '이불', qty: 1, price: 8000)],
    ),
  ];

  List<OrderModel> get orders => List.unmodifiable(_orders);
  OrderModel byId(String id) => _orders.firstWhere((o) => o.id == id);

  void nextStatus(String id) {
    final o = byId(id);
    switch (o.status) {
      case OrderStatus.pending: o.status = OrderStatus.approved; break;
      case OrderStatus.approved: o.status = OrderStatus.collected; break;
      case OrderStatus.collected: o.status = OrderStatus.washing; break;
      case OrderStatus.washing: o.status = OrderStatus.delivering; break;
      case OrderStatus.delivering: o.status = OrderStatus.done; break;
      case OrderStatus.done: break;
    }
    notifyListeners();
  }

  void togglePayment(String id) {
    final o = byId(id);
    o.payment = (o.payment == PaymentStatus.unpaid) ? PaymentStatus.paid : PaymentStatus.unpaid;
    notifyListeners();
  }
}

class RoleGateScreen extends StatelessWidget {
  const RoleGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('세탁수거배달')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton(
              onPressed: () => Navigator.pushNamed(context, '/customer/home'),
              child: const Text('고객 모드 열기'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, '/operator/dashboard'),
              child: const Text('운영자 모드 열기'),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('고객 홈')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionTitle('진행중 주문'),
          _OrderCardSimple(orderId: 'A2025-001'),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/order/create'),
            icon: const Icon(Icons.add),
            label: const Text('세탁 접수하기'),
          )
        ],
      ),
    );
  }
}

class OperatorDashboardScreen extends StatefulWidget {
  const OperatorDashboardScreen({super.key});
  @override
  State<OperatorDashboardScreen> createState() => _OperatorDashboardScreenState();
}

class _OperatorDashboardScreenState extends State<OperatorDashboardScreen> {
  final store = AppStore();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('운영자 대시보드')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: store.orders.length,
        itemBuilder: (context, index) {
          final o = store.orders[index];
          return _OrderAdminTile(
            order: o,
            onNext: () => setState(() => store.nextStatus(o.id)),
            onTogglePay: () => setState(() => store.togglePayment(o.id)),
          );
        },
      ),
    );
  }
}

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('주문 상세 (추후 구현)')));
  }
}

class OrderCreateScreen extends StatefulWidget {
  const OrderCreateScreen({super.key});
  @override
  State<OrderCreateScreen> createState() => _OrderCreateScreenState();
}

class _OrderCreateScreenState extends State<OrderCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final Map<String, int> catalog = const {'와이셔츠': 1900, '패딩': 5000, '이불': 8000};
  final Map<String, int> qty = {'와이셔츠': 0, '패딩': 0, '이불': 0};

  int get total => qty.entries.map((e) => (catalog[e.key] ?? 0) * e.value).fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('주문 접수')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: '이름'),
              validator: (v) => (v == null || v.isEmpty) ? '이름을 입력하세요' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addrCtrl,
              decoration: const InputDecoration(labelText: '주소(수동 입력)'),
              validator: (v) => (v == null || v.isEmpty) ? '주소를 입력하세요' : null,
            ),
            const SizedBox(height: 24),
            const Text('품목 선택', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...catalog.entries.map((e) => _QtyRow(
                  label: '${e.key} (${e.value}원)',
                  value: qty[e.key]!,
                  onChanged: (v) => setState(() => qty[e.key] = v),
                )),
            const SizedBox(height: 16),
            Text('합계: ${total}원', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 24),
            const Text('결제방법: 계좌입금(기록만)', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                if (_formKey.currentState!.validate() && total > 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('MVP: 주문이 생성되었습니다(로컬 목업).')),
                  );
                  Navigator.pop(context);
                } else if (total == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('품목 수량을 선택하세요.')),
                  );
                }
              },
              child: const Text('접수하기'),
            )
          ],
        ),
      ),
    );
  }
}

class _QtyRow extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  const _QtyRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            IconButton(onPressed: () => onChanged((value - 1).clamp(0, 99)), icon: const Icon(Icons.remove)),
            Text('$value'),
            IconButton(onPressed: () => onChanged((value + 1).clamp(0, 99)), icon: const Icon(Icons.add)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

class _OrderAdminTile extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onNext;
  final VoidCallback onTogglePay;
  const _OrderAdminTile({required this.order, required this.onNext, required this.onTogglePay});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(order.id, style: Theme.of(context).textTheme.titleMedium),
                const Text('승인대기 · 미납'),
              ],
            ),
            const SizedBox(height: 8),
            Text('${order.customerName} · ${order.address}', maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton(onPressed: onNext, child: const Text('다음 단계')),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: onTogglePay, child: const Text('결제 토글')),
                const Spacer(),
                Text('금액: ${order.amount.toString()}원'),
              ],
            )
          ],
        ),
      ),
    );
  }
}
