import 'package:flutter/material.dart';
import '../services/advisory_service.dart';

class FertilizerScreen extends StatefulWidget {
  const FertilizerScreen({super.key});
  @override
  State<FertilizerScreen> createState() => _FertilizerScreenState();
}

class _FertilizerScreenState extends State<FertilizerScreen> {
  final _crop = TextEditingController();
  final _n = TextEditingController(text: '50');
  final _p = TextEditingController(text: '40');
  final _k = TextEditingController(text: '30');
  Map<String, dynamic>? _result;
  bool _loading = false;

  Future<void> _recommend() async {
    if (_crop.text.trim().isEmpty) {
      _showError('Please enter a crop name.');
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await AdvisoryService.fertilizerRecommendation(
        crop: _crop.text.trim(),
        nitrogen: _parseValue(_n, 'nitrogen'),
        phosphorus: _parseValue(_p, 'phosphorus'),
        potassium: _parseValue(_k, 'potassium'),
      );
      if (mounted) setState(() => _result = result);
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$error')));
  }

  double _parseValue(TextEditingController controller, String label) {
    final value = double.tryParse(controller.text.trim());
    if (value == null || value < 0) {
      throw FormatException('Enter a valid non-negative $label value.');
    }
    return value;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Fertilizer Advice')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Enter crop and soil-test values (mg/kg).',
                style: TextStyle(fontWeight: FontWeight.w600)),
            TextField(
                controller: _crop,
                decoration: const InputDecoration(labelText: 'Crop')),
            Row(children: [
              Expanded(child: _numberField('N', _n)),
              const SizedBox(width: 8),
              Expanded(child: _numberField('P', _p)),
              const SizedBox(width: 8),
              Expanded(child: _numberField('K', _k)),
            ]),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loading ? null : _recommend,
              icon: const Icon(Icons.science_outlined),
              label: Text(_loading ? 'Checking...' : 'Get guidance'),
            ),
            if (_result != null) ...[
              const SizedBox(height: 20),
              Text('Nutrient status',
                  style: Theme.of(context).textTheme.titleLarge),
              ...(_result!['nutrient_status'] as List).map((item) => ListTile(
                    title: Text('${item['nutrient']}'),
                    subtitle: Text('${item['value']} mg/kg'),
                    trailing: Chip(label: Text('${item['status']}')),
                  )),
              const Divider(),
              ...(_result!['guidance'] as List).map((item) => ListTile(
                    leading: const Icon(Icons.check_circle_outline),
                    title: Text('$item'),
                  )),
              Text('${_result!['disclaimer']}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      );

  Widget _numberField(String label, TextEditingController controller) =>
      TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: label));
}

class MarketPricesScreen extends StatefulWidget {
  const MarketPricesScreen({super.key});
  @override
  State<MarketPricesScreen> createState() => _MarketPricesScreenState();
}

class _MarketPricesScreenState extends State<MarketPricesScreen> {
  final _crop = TextEditingController();
  final _location = TextEditingController(text: 'India');
  Map<String, dynamic>? _result;
  bool _loading = false;

  Future<void> _search() async {
    if (_crop.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a crop name.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await AdvisoryService.marketPrices(
          crop: _crop.text.trim(), location: _location.text.trim());
      if (mounted) setState(() => _result = result);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Market Prices')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          TextField(
              controller: _crop,
              decoration: const InputDecoration(labelText: 'Crop')),
          TextField(
              controller: _location,
              decoration:
                  const InputDecoration(labelText: 'State / market location')),
          const SizedBox(height: 12),
          FilledButton(
              onPressed: _loading ? null : _search,
              child: Text(_loading ? 'Checking...' : 'Find verified prices')),
          if (_result != null) ...[
            const SizedBox(height: 20),
            Text(
              'Status: ${_result!['status']}\nSource: ${_result!['source']}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (_result!['status'] != 'available')
              const Card(
                  child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                    'No verified price is available right now. We will not show an estimate as a live price.'),
              )),
            ...((_result!['records'] as List?) ?? const [])
                .map((record) => Card(
                        child: ListTile(
                      title: Text(
                          '${record['market'] ?? record['market_name'] ?? 'Market'}'),
                      subtitle: Text('${record['date'] ?? 'Date unavailable'}'),
                      trailing: Text(
                          '${record['price'] ?? record['modal_price'] ?? '--'}'),
                    ))),
          ],
        ]),
      );
}

class AgriculturalChatScreen extends StatefulWidget {
  const AgriculturalChatScreen({super.key});
  @override
  State<AgriculturalChatScreen> createState() => _AgriculturalChatScreenState();
}

class _AgriculturalChatScreenState extends State<AgriculturalChatScreen> {
  final _message = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _loading = false;

  Future<void> _send() async {
    final text = _message.text.trim();
    if (text.isEmpty || _loading) return;
    _message.clear();
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _loading = true;
    });
    try {
      final result =
          await AdvisoryService.chat(message: text, history: _messages);
      if (mounted)
        setState(() =>
            _messages.add({'role': 'model', 'text': '${result['answer']}'}));
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Ask Agri Expert')),
        body: Column(children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
                'For serious crop disease, soil, or safety decisions, consult a local agricultural professional.'),
          ),
          Expanded(
              child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length,
            itemBuilder: (_, index) => Align(
              alignment: _messages[index]['role'] == 'user'
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Card(
                  child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_messages[index]['text']!),
              )),
            ),
          )),
          if (_loading) const LinearProgressIndicator(),
          SafeArea(
              child: Row(children: [
            Expanded(
                child: TextField(
                    controller: _message,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                        hintText: 'Ask a farming question'))),
            IconButton(onPressed: _send, icon: const Icon(Icons.send)),
          ])),
        ]),
      );
}
