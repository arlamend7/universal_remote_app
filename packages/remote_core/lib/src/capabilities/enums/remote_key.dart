enum RemoteKey {
  digit0('0'),
  digit1('1'),
  digit2('2'),
  digit3('3'),
  digit4('4'),
  digit5('5'),
  digit6('6'),
  digit7('7'),
  digit8('8'),
  digit9('9'),
  dash('DASH'),
  enter('ENTER'),
  menu('MENU'),
  info('INFO'),
  guide('GUIDE'),
  exit('EXIT'),
  red('RED'),
  green('GREEN'),
  yellow('YELLOW'),
  blue('BLUE'),
  source('SOURCE'),
  settings('MENU'),
  mute('MUTE'),
  replay('REPLAY'),
  liveTv('LIVE_TV'),
  captions('CAPTIONS');

  const RemoteKey(this.wireName);
  final String wireName;
}
