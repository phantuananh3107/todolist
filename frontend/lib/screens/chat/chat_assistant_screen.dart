import 'package:flutter/material.dart';

import '../../models/task_item.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_refresh_bus.dart';
import '../../utils/auth_navigation.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/section_card.dart';

class ChatAssistantScreen extends StatefulWidget {
  const ChatAssistantScreen({super.key});

  @override
  State<ChatAssistantScreen> createState() => _ChatAssistantScreenState();
}

class _ChatAssistantScreenState extends State<ChatAssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<_Message> _messages = const [
    _Message(role: 'assistant', text: 'Sẵn sàng tối ưu thứ tự công việc và gợi ý lịch làm việc.'),
  ];
  List<TaskItem> _tasks = [];
  bool _sending = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    AppRefreshBus.tasks.addListener(_loadData);
    _loadData();
  }

  @override
  void dispose() {
    AppRefreshBus.tasks.removeListener(_loadData);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final tasks = await ApiService.fetchTasks();
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _tasks = demoTasks;
        _loading = false;
      });
    }
  }

  List<TaskItem> get _rankedTasks {
    final items = List<TaskItem>.from(_tasks.where((e) => e.status != 'DONE'));
    const weight = {'HIGH': 3, 'MEDIUM': 2, 'LOW': 1};
    items.sort((a, b) {
      final p = (weight[b.priority] ?? 0) - (weight[a.priority] ?? 0);
      if (p != 0) return p;
      return a.dueDate.compareTo(b.dueDate);
    });
    return items;
  }

  int get _doneCount => _tasks.where((e) => e.status == 'DONE').length;
  int get _doingCount => _tasks.where((e) => e.status == 'DOING').length;
  int get _urgentCount => _rankedTasks.where((e) => e.priority == 'HIGH').length;

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _messages = [..._messages, _Message(role: 'user', text: text)];
      _sending = true;
      _controller.clear();
    });
    _scrollToBottom();
    try {
      final taskContext = ApiService.buildTaskContext(_tasks);
      final response = await ApiService.sendChat([
        {
          'role': 'system',
          'content': 'Bạn là trợ lý ưu tiên công việc. Hãy trả lời ngắn gọn, bằng tiếng Việt, bám sát dữ liệu sau.\n$taskContext',
        },
        ..._messages.map((e) => {'role': e.role, 'content': e.text}),
      ]);
      if (!mounted) return;
      setState(() => _messages = [..._messages, _Message(role: 'assistant', text: response)]);
    } catch (e) {
      if (ApiService.isUnauthorized(e)) {
        if (!mounted) return;
        await handleUnauthorized(context);
        return;
      }
      if (!mounted) return;
      setState(() => _messages = [..._messages, _Message(role: 'assistant', text: _fallbackReply(text))]);
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  String _fallbackReply(String prompt) {
    final lower = prompt.toLowerCase();
    final ranked = _rankedTasks.take(3).toList();
    if (ranked.isEmpty) return 'Chưa có dữ liệu công việc để phân tích.';
    if (lower.contains('lịch') || lower.contains('schedule')) {
      return ranked.asMap().entries.map((entry) {
        final hour = 9 + entry.key * 2;
        final task = entry.value;
        return '${entry.key + 1}. ${task.title} • ${hour.toString().padLeft(2, '0')}:00';
      }).join('\n');
    }
    if (lower.contains('task') || lower.contains('công việc') || lower.contains('ưu tiên')) {
      return ranked.asMap().entries.map((entry) {
        final task = entry.value;
        return '${entry.key + 1}. ${task.title} • ${task.priority} • ${task.status}';
      }).join('\n');
    }
    return 'Ưu tiên hiện tại: ${ranked.map((e) => e.title).join(' → ')}';
  }

  void _resetConversation() {
    setState(() {
      _messages = const [
        _Message(role: 'assistant', text: 'Sẵn sàng tối ưu thứ tự công việc và gợi ý lịch làm việc.'),
      ];
    });
  }

  void _applyLocalSchedule() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã áp dụng thứ tự đề xuất trong phiên hiện tại.')),
    );
    AppRefreshBus.bumpTasks();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final ranked = _rankedTasks.take(3).toList();
    final suggestions = const [
      'Ưu tiên việc hôm nay',
      'Lập lịch cho 3 task',
      'Việc nào gần hạn nhất?',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Priority Assistant'),
        actions: [
          IconButton(onPressed: _resetConversation, tooltip: 'Làm mới hội thoại', icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    children: [
                      SectionCard(
                        gradient: const LinearGradient(colors: [Color(0xFFFF6A3D), Color(0xFFFF8F5C)]),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('AI Priority Assistant', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
                            const SizedBox(height: 8),
                            Text('Tạo thứ tự ưu tiên và gợi ý lịch làm việc từ danh sách công việc hiện tại.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(.92))),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: _MetricCard(label: 'Đang làm', value: '$_doingCount', accent: AppColors.warning)),
                                const SizedBox(width: 10),
                                Expanded(child: _MetricCard(label: 'Đã xong', value: '$_doneCount', accent: AppColors.success)),
                                const SizedBox(width: 10),
                                Expanded(child: _MetricCard(label: 'Gấp', value: '$_urgentCount', accent: AppColors.danger)),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primaryDark),
                                onPressed: () => _send('Lập lịch cho 3 task sắp tới'),
                                child: const Text('Generate AI Schedule'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: suggestions
                            .map((text) => ActionChip(
                                  label: Text(text, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700)),
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(color: AppColors.border),
                                  onPressed: () => _send(text),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text('Recommended Order', style: Theme.of(context).textTheme.titleLarge)),
                                if (ranked.isNotEmpty)
                                  TextButton(onPressed: () => _send('Lập lịch cho 3 task sắp tới'), child: const Text('Re-generate')),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (ranked.isEmpty)
                              const EmptyStateCard(icon: Icons.auto_awesome_outlined, title: 'Chưa có công việc mở', message: 'Tạo thêm task để AI đề xuất thứ tự xử lý.')
                            else
                              ...ranked.asMap().entries.map((entry) {
                                final task = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceMuted,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(radius: 14, backgroundColor: AppColors.primary, child: Text('${entry.key + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(task.title, style: Theme.of(context).textTheme.titleMedium),
                                              const SizedBox(height: 4),
                                              Text('Hạn ${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year} • ${task.priority}', style: Theme.of(context).textTheme.bodyMedium),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            if (ranked.isNotEmpty)
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: _applyLocalSchedule,
                                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0E1730), foregroundColor: Colors.white),
                                  child: const Text('Apply this Schedule'),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._messages.map((message) => Align(
                            alignment: message.role == 'user' ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 720),
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: message.role == 'user' ? AppColors.primary : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(message.text, style: TextStyle(color: message.role == 'user' ? Colors.white : AppColors.text, height: 1.5)),
                            ),
                          )),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            minLines: 1,
                            maxLines: 4,
                            decoration: const InputDecoration(hintText: 'Nhập yêu cầu cho AI'),
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FloatingActionButton.small(
                          onPressed: _sending ? null : _send,
                          child: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.accent});

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white.withOpacity(.92), borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.text)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: accent, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _Message {
  const _Message({required this.role, required this.text});
  final String role;
  final String text;
}
