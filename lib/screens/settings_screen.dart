import 'package:flutter/material.dart';
import '../main.dart' show themeNotifier;
import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _bildirimler = true;
  bool _konumIzni = true;
  String _seciliDil = 'Türkçe';

  bool get _karanlikMod => themeNotifier.value == ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: Column(
        children: [
          // ── AppBar ──────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3949AB),
                  const Color(0xFF3949AB).withOpacity(0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3949AB).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Ayarlar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── İçerik ──────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Profil kartı
                StreamBuilder<Map<String, dynamic>?>(
                  stream: AuthService().userDataStream(),
                  builder: (context, userSnap) {
                    return StreamBuilder<Map<String, dynamic>?>(
                      stream: AuthService().companyDataStream(),
                      builder: (context, companySnap) {
                        final user = userSnap.data;
                        final company = companySnap.data;
                        final name = user?['name'] as String? ?? '—';
                        final email = user?['email'] as String? ?? '—';
                        final companyName = company?['name'] as String? ?? '—';
                        final role = user?['role'] as String? ?? 'employee';
                        final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(isDark ? 0.3 : 0.07),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: colorScheme.primaryContainer,
                                child: userSnap.connectionState ==
                                        ConnectionState.waiting
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: colorScheme.primary,
                                        ),
                                      )
                                    : Text(
                                        initial,
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      email,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: colorScheme.primaryContainer,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            companyName,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme
                                                  .onPrimaryContainer,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: role == 'admin'
                                                ? Colors.orange.withOpacity(0.15)
                                                : colorScheme.surfaceContainerHighest,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            role == 'admin' ? 'Admin' : 'Çalışan',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: role == 'admin'
                                                  ? Colors.orange
                                                  : colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 20),
                const _SectionTitle('Uygulama'),
                const SizedBox(height: 8),

                _SettingsCard(
                  isDark: isDark,
                  children: [
                    _SwitchTile(
                      icon: Icons.notifications_outlined,
                      iconColor: Colors.orange,
                      title: 'Bildirimler',
                      subtitle: 'Teslimat hatırlatmaları',
                      value: _bildirimler,
                      onChanged: (v) => setState(() => _bildirimler = v),
                    ),
                    Divider(height: 1, indent: 56, color: colorScheme.outlineVariant),
                    _SwitchTile(
                      icon: Icons.location_on_outlined,
                      iconColor: Colors.green,
                      title: 'Konum İzni',
                      subtitle: 'Yakın teslimatları göster',
                      value: _konumIzni,
                      onChanged: (v) => setState(() => _konumIzni = v),
                    ),
                    Divider(height: 1, indent: 56, color: colorScheme.outlineVariant),
                    _SwitchTile(
                      icon: Icons.dark_mode_outlined,
                      iconColor: Colors.indigo,
                      title: 'Karanlık Mod',
                      subtitle: 'Gece temasını kullan',
                      value: _karanlikMod,
                      onChanged: (v) {
                        themeNotifier.value =
                            v ? ThemeMode.dark : ThemeMode.light;
                        setState(() {});
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const _SectionTitle('Tercihler'),
                const SizedBox(height: 8),

                _SettingsCard(
                  isDark: isDark,
                  children: [
                    _SelectTile(
                      icon: Icons.language_outlined,
                      iconColor: Colors.blue,
                      title: 'Dil',
                      value: _seciliDil,
                      options: const ['Türkçe', 'English', 'Deutsch'],
                      onChanged: (v) => setState(() => _seciliDil = v),
                    ),
                    Divider(height: 1, indent: 56, color: colorScheme.outlineVariant),
                    _NavTile(
                      icon: Icons.map_outlined,
                      iconColor: Colors.teal,
                      title: 'Harita Türü',
                      subtitle: 'OpenStreetMap',
                      onTap: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const _SectionTitle('Hakkında'),
                const SizedBox(height: 8),

                _SettingsCard(
                  isDark: isDark,
                  children: [
                    _NavTile(
                      icon: Icons.info_outline_rounded,
                      iconColor: Colors.blueGrey,
                      title: 'Uygulama Sürümü',
                      subtitle: '1.0.0',
                      onTap: () {},
                    ),
                    Divider(height: 1, indent: 56, color: colorScheme.outlineVariant),
                    _NavTile(
                      icon: Icons.privacy_tip_outlined,
                      iconColor: Colors.purple,
                      title: 'Gizlilik Politikası',
                      onTap: () {},
                    ),
                    Divider(height: 1, indent: 56, color: colorScheme.outlineVariant),
                    _NavTile(
                      icon: Icons.description_outlined,
                      iconColor: Colors.brown,
                      title: 'Kullanım Koşulları',
                      onTap: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.07),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.logout_rounded,
                          color: Colors.red, size: 18),
                    ),
                    title: const Text(
                      'Çıkış Yap',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.w600),
                    ),
                    onTap: () => AuthService().signOut(),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Yardımcı widget'lar ──────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;
  const _SettingsCard({required this.children, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _IconBox(icon: icon, color: iconColor),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant))
          : null,
      trailing: Switch.adaptive(value: value, onChanged: onChanged),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _IconBox(icon: icon, color: iconColor),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant))
          : null,
      trailing: Icon(Icons.chevron_right,
          color: Theme.of(context).colorScheme.outlineVariant),
      onTap: onTap,
    );
  }
}

class _SelectTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _SelectTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: _IconBox(icon: icon, color: iconColor),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: colorScheme.surfaceContainer,
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: (v) => v != null ? onChanged(v) : null,
          style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500),
          icon: Icon(Icons.expand_more,
              color: colorScheme.onSurfaceVariant, size: 18),
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IconBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}
