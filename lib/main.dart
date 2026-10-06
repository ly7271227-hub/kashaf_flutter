import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const KashafApp());

class KashafApp extends StatelessWidget {
  const KashafApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF070712),
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7C4DFF), brightness: Brightness.dark),
        ),
        home: const FlashlightPage(),
      );
}

class FlashlightPage extends StatefulWidget {
  const FlashlightPage({super.key});
  @override State<FlashlightPage> createState() => _FlashlightPageState();
}

class _FlashlightPageState extends State<FlashlightPage> {
  static const _torch = MethodChannel('kashaf/torch');
  bool isOn = false, sos = false, screenLight = false;
  Timer? sosTimer, countdownTimer;
  Duration remaining = Duration.zero;

  Future<bool> setTorch(bool value) async {
    try {
      await _torch.invokeMethod('setTorch', {'enabled': value});
      if (mounted) setState(() => isOn = value);
      return true;
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تشغيل فلاش الهاتف')));
      return false;
    }
  }

  void toggleSos() {
    if (sos) { sosTimer?.cancel(); sosTimer = null; setState(() => sos = false); setTorch(false); return; }
    setState(() => sos = true);
    bool state = false;
    sosTimer = Timer.periodic(const Duration(milliseconds: 350), (_) { state = !state; setTorch(state); });
  }

  void startCountdown(int totalSeconds) {
    countdownTimer?.cancel();
    setState(() => remaining = Duration(seconds: totalSeconds));
    setTorch(true);
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remaining.inSeconds <= 1) {
        t.cancel(); setState(() => remaining = Duration.zero); setTorch(false); _alarm();
      } else { setState(() => remaining -= const Duration(seconds: 1)); }
    });
  }

  void cancelCountdown() { countdownTimer?.cancel(); setState(() => remaining = Duration.zero); }

  Future<void> _alarm() async {
    for (int i = 0; i < 5; i++) { await SystemSound.play(SystemSoundType.alert); await Future.delayed(const Duration(milliseconds: 350)); }
    if (!mounted) return;
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF171528), title: const Text('⏰ انتهى المؤقت'),
      content: const Text('تم إطفاء الكشاف وانتهى الوقت المحدد.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسنًا'))],
    ));
  }

  String format(Duration d) => '${d.inHours.toString().padLeft(2,'0')}:${d.inMinutes.remainder(60).toString().padLeft(2,'0')}:${d.inSeconds.remainder(60).toString().padLeft(2,'0')}';

  void openTimer() {
    int hours = 0, minutes = 1, seconds = 0;
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: const Color(0xFF111020),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) => Padding(
        padding: EdgeInsets.fromLTRB(22,24,22,MediaQuery.of(ctx).viewInsets.bottom+25),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width:45,height:5,decoration:BoxDecoration(color:Colors.white24,borderRadius:BorderRadius.circular(10))), const SizedBox(height:20),
          const Text('⏱ مؤقت الكشاف', style: TextStyle(fontSize:24,fontWeight:FontWeight.bold)), const SizedBox(height:8),
          const Text('اختر الساعات والدقائق والثواني', style: TextStyle(color:Colors.white54)), const SizedBox(height:25),
          Row(mainAxisAlignment:MainAxisAlignment.center,children:[_picker('ساعات',hours,25,(v)=>setSheet(()=>hours=v)),_picker('دقائق',minutes,60,(v)=>setSheet(()=>minutes=v)),_picker('ثواني',seconds,60,(v)=>setSheet(()=>seconds=v))]),
          const SizedBox(height:25), SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:(){final total=hours*3600+minutes*60+seconds;if(total==0)return;Navigator.pop(ctx);startCountdown(total);},icon:const Icon(Icons.play_arrow_rounded),label:const Text('تشغيل المؤقت'),style:FilledButton.styleFrom(padding:const EdgeInsets.symmetric(vertical:16))))
        ]))));
  }

  Widget _picker(String label,int value,int max,ValueChanged<int> onChanged)=>Expanded(child:Column(children:[Text(label,style:const TextStyle(color:Colors.white54)),const SizedBox(height:6),DropdownButton<int>(value:value,dropdownColor:const Color(0xFF242039),underline:const SizedBox(),items:List.generate(max,(i)=>DropdownMenuItem(value:i,child:Text(i.toString().padLeft(2,'0'),style:const TextStyle(fontSize:23,fontWeight:FontWeight.bold)))),onChanged:(v){if(v!=null)onChanged(v);})]));

  @override void dispose(){sosTimer?.cancel();countdownTimer?.cancel();setTorch(false);super.dispose();}

  @override Widget build(BuildContext context){
    final bg=screenLight?Colors.white:const Color(0xFF070712),fg=screenLight?Colors.black:Colors.white;
    return Scaffold(backgroundColor:bg,body:SafeArea(child:Stack(children:[
      Positioned(top:-100,right:-80,child:_glow(const Color(0xFF7C4DFF),260)), Positioned(bottom:30,left:-100,child:_glow(const Color(0xFF00D9FF),220)),
      Padding(padding:const EdgeInsets.fromLTRB(20,18,20,15),child:Column(children:[
        Row(children:[Container(width:48,height:48,decoration:BoxDecoration(color:const Color(0xFF17152A),borderRadius:BorderRadius.circular(16)),child:const Icon(Icons.flashlight_on_rounded,color:Color(0xFFB99AFF))),const SizedBox(width:12),Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('كشاف',style:TextStyle(color:fg,fontSize:25,fontWeight:FontWeight.w800)),Text('ضوء ذكي وسريع',style:TextStyle(color:screenLight?Colors.grey:Colors.white54))]),const Spacer(),IconButton(onPressed:()=>setState(()=>screenLight=!screenLight),icon:Icon(screenLight?Icons.dark_mode_rounded:Icons.light_mode_rounded,color:fg))]),
        const Spacer(),GestureDetector(onTap:()=>setTorch(!isOn),child:AnimatedContainer(duration:const Duration(milliseconds:300),width:230,height:230,decoration:BoxDecoration(shape:BoxShape.circle,gradient:isOn?const RadialGradient(colors:[Colors.white,Color(0xFFB9A7FF),Color(0xFF5E35B1)]):const RadialGradient(colors:[Color(0xFF27233D),Color(0xFF0E0D18)]),boxShadow:isOn?[const BoxShadow(color:Color(0x997C4DFF),blurRadius:75,spreadRadius:8)]:[const BoxShadow(color:Colors.black54,blurRadius:30)]),child:Center(child:Icon(Icons.flashlight_on_rounded,size:88,color:isOn?Colors.black:Colors.white)))),
        const SizedBox(height:25),Text(isOn?'الكشاف يعمل':'الكشاف متوقف',style:TextStyle(color:fg,fontSize:19,fontWeight:FontWeight.w600)),
        if(remaining>Duration.zero)...[const SizedBox(height:10),Text(format(remaining),style:const TextStyle(fontSize:30,fontWeight:FontWeight.bold,letterSpacing:3,color:Color(0xFFB99AFF))),TextButton(onPressed:cancelCountdown,child:const Text('إلغاء المؤقت'))],
        const Spacer(),Row(children:[_card(Icons.timer_rounded,'المؤقت','ثواني • دقائق • ساعات',openTimer,const Color(0xFF7C4DFF)),const SizedBox(width:12),_card(Icons.sos_rounded,'SOS','وميض للطوارئ',toggleSos,const Color(0xFFFF4D7D),active:sos)]),const SizedBox(height:12),_card(Icons.screen_lock_portrait_rounded,'ضوء الشاشة',screenLight?'مفعل':'بديل للفلاش',()=>setState(()=>screenLight=!screenLight),const Color(0xFF00CFFF),active:screenLight)
      ]))])));
  }
  Widget _glow(Color color,double size)=>IgnorePointer(child:Container(width:size,height:size,decoration:BoxDecoration(shape:BoxShape.circle,gradient:RadialGradient(colors:[color.withOpacity(.18),Colors.transparent]))));
  Widget _card(IconData icon,String title,String sub,VoidCallback onTap,Color color,{bool active=false})=>Expanded(child:GestureDetector(onTap:onTap,child:AnimatedContainer(duration:const Duration(milliseconds:200),padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:active?color.withOpacity(.22):const Color(0xFF111020),borderRadius:BorderRadius.circular(20),border:Border.all(color:active?color:Colors.white10)),child:Row(children:[Icon(icon,color:color,size:29),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:16)),const SizedBox(height:3),Text(sub,style:const TextStyle(color:Colors.white54,fontSize:11),overflow:TextOverflow.ellipsis)]))]))));
}