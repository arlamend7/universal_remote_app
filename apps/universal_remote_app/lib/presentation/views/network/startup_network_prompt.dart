import 'package:flutter/widgets.dart';

import 'startup_network_prompt_state.dart';

class StartupNetworkPrompt extends StatefulWidget {
  const StartupNetworkPrompt({super.key, required this.child});

  final Widget child;

  @override
  State<StartupNetworkPrompt> createState() => StartupNetworkPromptState();
}
