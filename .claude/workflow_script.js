export const meta = {
  name: 'dostok-round-5-fixes',
  description: 'Fix chat null crash at input, call screen black flash + orb redesign, bottom nav architecture',
  phases: [
    { title: 'Structural', detail: 'Fix MaterialApp builder black flash + restructure nav with persistent bottom nav shell' },
    { title: 'Screen Fixes', detail: 'Parallel: chat crash fix + call screen polish and unique 3D orb' },
    { title: 'Verification', detail: 'Flutter analyze + release APK build' },
  ],
};

phase('Structural');

const structural = await agent(
  'You are the Structural Navigation Agent for Dostok.\n' +
  '\n' +
  'The user reports THREE structural issues:\n' +
  '1. Call/voice screen shows half black for a second — this is likely because MaterialApp.builder returns SizedBox.shrink() during route transitions.\n' +
  '2. Bottom navigation bar does not show which tab the user is on, and disappears when navigating to Chat/Daily/Settings because those are pushed as new routes.\n' +
  '3. The bottom nav center FAB (index 2) and Chat (index 3) both push to /chat, but there is no active-tab indication because each screen is a separate route.\n' +
  '\n' +
  'Your job: Fix navigation architecture so the bottom nav is ALWAYS visible on main tabs and shows the active tab.\n' +
  '\n' +
  '## Files to modify:\n' +
  '\n' +
  '1. lib/app.dart — READ first.\n' +
  '   a. Fix the builder to avoid black flash during transitions. Instead of\n' +
  '      builder: (context, child) => child ?? const SizedBox.shrink(),\n' +
  '      use a wrapper that preserves the scaffold background color:\n' +
  '      builder: (context, child) {\n' +
  '        final theme = Theme.of(context);\n' +
  '        return Container(\n' +
  '          color: theme.scaffoldBackgroundColor,\n' +
  '          child: child,\n' +
  '        );\n' +
  '      },\n' +
  '      This prevents any black gap during Hero or route transitions.\n' +
  '   b. Change routes so main tabs are inside a shell. Replace the direct routes:\n' +
  '      - /home should point to a new MainShell screen (see below)\n' +
  '      - Keep /splash, /onboarding, /call as direct routes (call is full-screen)\n' +
  '      - Keep /chat, /daily, /settings as direct routes for deep-linking, but the shell should use the tab screens directly.\n' +
  '\n' +
  '2. Create lib/screens/main_shell.dart — NEW FILE.\n' +
  '   This is the root shell for the 4 main tabs (Home, Daily, Chat, Settings) plus the center FAB.\n' +
  '   Use a StatefulWidget with IndexedStack for the body so tabs maintain their state.\n' +
  '   \n' +
  '   class MainShell extends StatefulWidget {\n' +
  '     final int initialIndex;\n' +
  '     const MainShell({super.key, this.initialIndex = 0});\n' +
  '     ...\n' +
  '   }\n' +
  '   \n' +
  '   The body should be an IndexedStack with these children in order:\n' +
  '   - index 0: HomeScreen (existing, but remove its internal bottom nav)\n' +
  '   - index 1: DailyScreen (existing)\n' +
  '   - index 2: ChatScreen (existing)\n' +
  '   - index 3: SettingsScreen (existing)\n' +
  '   \n' +
  '   The bottom nav should use DostokBottomNav (existing widget at lib/widgets/bottom_nav.dart) but you may need to modify it. The center FAB should navigate to Chat (index 2) — NOT index 2 in the bottom nav items.\n' +
  '   \n' +
  '   The mapping:\n' +
  '   - bottomNavIndex 0 -> tab 0 (Home)\n' +
  '   - bottomNavIndex 1 -> tab 1 (Daily)\n' +
  '   - bottomNavIndex 2 -> tab 2 (Chat)  [center FAB]\n' +
  '   - bottomNavIndex 3 -> tab 2 (Chat)  [Chat icon]  -> same as FAB\n' +
  '   - bottomNavIndex 4 -> tab 3 (Settings)\n' +
  '   \n' +
  '   In MainShell, onTap should call setState to switch _currentIndex, and use IndexedStack(children: [HomeScreen(), DailyScreen(), ChatScreen(), SettingsScreen()]).\n' +
  '   \n' +
  '   IMPORTANT: Remove the Scaffold + bottomNavigationBar from HomeScreen. HomeScreen currently has its own bottom nav (DostokBottomNav). Remove it so HomeScreen is just the body content. The shell provides the nav.\n' +
  '\n' +
  '3. lib/screens/home_screen.dart — READ first.\n' +
  '   Remove the bottomNavigationBar and the _currentIndex state. The HomeScreen should only return a Scaffold with backgroundColor and body: _HomeBody(). Remove the DostokBottomNav import if no longer needed.\n' +
  '   The home body CTA buttons can still use Navigator.pushNamed(context, /chat) for deep navigation, or ideally just rely on the bottom nav. Keep it simple for now.\n' +
  '\n' +
  '4. lib/widgets/bottom_nav.dart — READ first.\n' +
  '   Modify DostokBottomNav to accept a background color that adapts to dark mode (currently hardcoded Colors.white). Use:\n' +
  '   color: Theme.of(context).bottomNavigationBarTheme.backgroundColor ?? Colors.white\n' +
  '   Also update the shadow color to use AppColors.primary.withValues(alpha: 0.15) or theme-based shadow.\n' +
  '   Keep the same 5-item layout.\n' +
  '\n' +
  '5. lib/screens/call_screen.dart — Ensure the Scaffold has an explicit backgroundColor: AppColors.background.\n' +
  '   This prevents any black flash during push transitions.\n' +
  '\n' +
  'DO NOT touch chat_screen.dart, onboarding_screen.dart, or theme files. Return a concise list of changes.',
  { label: 'Structural: Nav + Black Flash' }
);

phase('Screen Fixes');

const results = await parallel([
  () => agent(
    'You are the Chat Crash Fix Agent for Dostok.\n' +
    '\n' +
    'The user reports: "chat it says u gave null operator to null value and and show where i write." The crash happens when the user is typing or in the text input area. The root cause is likely corrupted messages in the Hive box that have null fields at runtime (content, timestamp, etc.), even though the Message model declares them non-nullable.\n' +
    '\n' +
    '## Files to modify:\n' +
    '\n' +
    '1. lib/providers/chat_provider.dart — READ the full file first.\n' +
    '   a. In loadMessages(), after detecting item is Message, VALIDATE the deserialized Message before returning it. Since Hive may have stored corrupted messages with null fields, add a try-catch that force-accesses all fields to trigger implicit null checks:\n' +
    '   if (item is Message) {\n' +
    '     try {\n' +
    '       // Force runtime validation of non-nullable fields\n' +
    '       final _ = item.id + item.content + item.timestamp.toIso8601String();\n' +
    '       return item;\n' +
    '     } catch (e) {\n' +
    '       dev.log("Corrupted Hive message skipped: \$e");\n' +
    '       return null;\n' +
    '     }\n' +
    '   }\n' +
    '   Then chain .where((m) => m != null).cast<Message>().toList() after the map.\n' +
    '   b. Also wrap the ENTIRE inside of the raw.map((item) { ... }).toList() in a try-catch so one bad message does not kill the whole list. If a single message fails, return null for it, then filter nulls.\n' +
    '   c. In sendMessage() and sendVoiceMessage(), ensure the created Message has all non-null fields. They already do — just double-check.\n' +
    '   d. In _persistMessage(), add a try-catch around the entire body and log if persistence fails. Also ensure the box value is a List<dynamic>.\n' +
    '   e. In _fetchAiResponse(), if the response body is empty or jsonDecode fails, return a safe fallback string.\n' +
    '   f. In _getDemoResponse(), ensure all strings are non-null (they are hardcoded). Keep them in English as already changed.\n' +
    '\n' +
    '2. lib/screens/chat_screen.dart — READ the full file.\n' +
    '   a. In _buildMessageList, wrap the Column return in a try-catch:\n' +
    '   try {\n' +
    '     final message = messages[index];\n' +
    '     ... build the column ...\n' +
    '   } catch (e, st) {\n' +
    '     debugPrint("Message render error: \$e");\n' +
    '     return const SizedBox.shrink();\n' +
    '   }\n' +
    '   This prevents a single corrupted message from crashing the entire chat list.\n' +
    '   b. In _buildTextBubble, at the very start, add a defensive guard:\n' +
    '   if (message.content.isEmpty && message.type != MessageType.audio) {\n' +
    '     return const SizedBox.shrink();\n' +
    '   }\n' +
    '   c. Ensure _formatTime(DateTime? dt) and _buildDateSeparator(DateTime? date) handle null gracefully (already done in round 4, verify and strengthen if needed).\n' +
    '   d. Check the input area (_buildInputArea). The text field background is hardcoded Color(0xFFF5F3FF) which is a light purple that clashes with the new teal theme. Change it to AppColors.primaryContainer (which is now a light teal). Also change the Container background in input area from Colors.white to AppColors.surface so it respects the theme.\n' +
    '   e. Make the input text field text color adapt to dark mode. Instead of hardcoding color: AppColors.textPrimary, use color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textPrimary for the TextField style. Same for hintStyle — use AppColors.textSecondary which should contrast okay, but ideally use theme-aware colors.\n' +
    '   f. Ensure _buildInputArea uses theme-aware colors instead of hardcoded Colors.white and Color(0xFFF5F3FF).\n' +
    '\n' +
    'DO NOT touch app.dart or navigation files. Return a list of changes.',
    { label: 'Chat Crash Fix' }
  ),

  () => agent(
    'You are the Call Screen Polish Agent for Dostok.\n' +
    '\n' +
    'The user reports TWO issues:\n' +
    '1. "Voice screen show a half black for a second" — a flash of black/blank when opening the call screen.\n' +
    '2. "The orb in voice call screen does not show something unique and 3D it shows just a double sphere" — the orb looks like overlapping circles, not a true 3D holographic sphere.\n' +
    '\n' +
    '## File to modify: lib/screens/call_screen.dart\n' +
    '\n' +
    '### Issue 1: Black flash\n' +
    '- Ensure the Scaffold has an explicit backgroundColor: AppColors.background.\n' +
    '- Ensure all AnimatedBuilder / AnimatedContainer widgets have explicit colors, not relying on default black backgrounds.\n' +
    '- The summary fade controller or any AnimatedOpacity should start from the scaffold background color, not from transparent (which may show black underneath during the push transition).\n' +
    '- Add extendBodyBehindAppBar: true or just ensure the background fills the entire screen. Make sure there are NO Container widgets with null/default colors that could flash black.\n' +
    '\n' +
    '### Issue 2: Unique 3D orb redesign\n' +
    'The current orb is probably multiple overlapping Container circles with radial/sweep gradients. The user sees this as "just a double sphere."\n' +
    '\n' +
    'You must redesign the orb to feel TRULY 3D, alive, and premium. Here is the exact design to implement:\n' +
    '\n' +
    'New 3D Living Orb Design:\n' +
    '\n' +
    'Use a Stack with these layers, all centered, sized at 240px:\n' +
    '\n' +
    '1. Outer Aura Glow — A large soft glow behind everything. Use avatar_glow package (already in pubspec dependencies) OR a manual AnimatedContainer that breathes:\n' +
    '   - A Container 300px, BoxShape.circle, with a BoxShadow that has large blurRadius (60) and spreadRadius (8), color: AppColors.primary.withValues(alpha: 0.25). Animate its scale with a sine wave (breathing: 1.0 to 1.08 over 4s).\n' +
    '\n' +
    '2. Base Sphere — A 240px circle with a true 3D-looking radial gradient that mimics a lit sphere:\n' +
    '   RadialGradient(\n' +
    '     center: Alignment(-0.3, -0.4), // light source top-left\n' +
    '     radius: 0.85,\n' +
    '     colors: [\n' +
    '       Color(0xFFCCFBF1),  // highlight (bright cyan-white)\n' +
    '       Color(0xFF5EEAD4),  // mid-tone\n' +
    '       Color(0xFF14B8A6),  // teal body\n' +
    '       Color(0xFF0D9488),  // shadow side\n' +
    '       Color(0xFF0F766E),  // deep shadow\n' +
    '     ],\n' +
    '     stops: [0.0, 0.25, 0.5, 0.75, 1.0],\n' +
    '   )\n' +
    '\n' +
    '3. Specular Highlight (the "glint") — NOT a circle. A rotated oval/ellipse positioned at top-left inside the sphere, white with opacity 0.5, using a blur or soft gradient. This should look like a window reflection on a glass sphere.\n' +
    '   - Use a Container with borderRadius (not circle), width 50, height 28, rotated -15 degrees, with a LinearGradient from white 0.6 to transparent.\n' +
    '   - Position it at top: 45, left: 55.\n' +
    '\n' +
    '4. Inner Depth Ring — A smaller circle (180px) with a very subtle inner shadow effect. Since Flutter can not do inner shadow easily, fake it with a radial gradient that goes from transparent in the center to a dark teal ring at the edge:\n' +
    '   RadialGradient(\n' +
    '     colors: [Colors.transparent, Color(0x1A0F766E), Colors.transparent],\n' +
    '     stops: [0.5, 0.75, 1.0],\n' +
    '   )\n' +
    '   This creates a "hollow sphere" depth feel.\n' +
    '\n' +
    '5. Rotating Rim Light — A SweepGradient on a 240px circle that rotates slowly (8s). Use teal/cyan colors at low alpha so it looks like light sweeping across the sphere surface:\n' +
    '   SweepGradient(\n' +
    '     colors: [\n' +
    '       Colors.transparent,\n' +
    '       Color(0x405EEAD4),\n' +
    '       Color(0x2014B8A6),\n' +
    '       Colors.transparent,\n' +
    '     ],\n' +
    '   )\n' +
    '\n' +
    '6. Caustic Reflection (bottom) — A small soft oval at the bottom of the sphere (like light refracting through glass). White with alpha 0.15, blurred, positioned at bottom center, width 60, height 20, borderRadius 30.\n' +
    '\n' +
    '7. Ambient Particle Ring — 6-8 tiny dots (4px) orbiting the sphere in a slow circular path (12s). Each dot is white with varying alpha (0.3-0.6). Use AnimatedBuilder with different phase offsets for each dot. Position them around the sphere at radius 130px.\n' +
    '\n' +
    'Critical: Do NOT just stack 2-3 circles with radial gradients. Use at least 6 distinct layers with unique shapes (ovals, rings, particles) so it looks like a living 3D glass orb, not "a double sphere."\n' +
    '\n' +
    'Layout cleanup:\n' +
    '- Keep status text elegant: "Calling...", "Connected", "On a call" with premium typography.\n' +
    '- End call button: prominent red circle, 72px, centered at bottom.\n' +
    '- Mute / Speaker: 52px circles above end call, with clear active/inactive states.\n' +
    '- Add a subtle background gradient to the whole screen using AppColors.dreamyBg.\n' +
    '\n' +
    'Return a list of all changes and describe the new orb design.',
    { label: 'Call Screen Polish' }
  ),
]);

phase('Verification');

const verify = await agent(
  'You are the Build Verification Agent for Dostok.\n' +
  '\n' +
  'Run these commands in the project root and report the EXACT output:\n' +
  '1. flutter analyze\n' +
  '2. flutter build apk --release\n' +
  '\n' +
  'If there are any errors or warnings in the changed files (main_shell.dart, app.dart, home_screen.dart, bottom_nav.dart, call_screen.dart, chat_screen.dart, chat_provider.dart), report them verbatim.\n' +
  '\n' +
  'Project is at /home/hotoke/Documents/side_quests/Friend.',
  { label: 'Build Verify' }
);
