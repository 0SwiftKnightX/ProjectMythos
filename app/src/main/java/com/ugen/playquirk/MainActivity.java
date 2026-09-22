package com.ugen.playquirk;

import android.app.*; import android.os.*; import android.content.*; import android.graphics.Color; import android.view.*; import android.widget.*; import java.util.*;

public class MainActivity extends Activity {
 LinearLayout root, content; android.content.SharedPreferences p; ArrayList<String> chars=new ArrayList<>();
 int dp(float v){return (int)(v*getResources().getDisplayMetrics().density+.5f);} TextView tv(String s,int z){TextView t=new TextView(this);t.setText(s);t.setTextColor(Color.WHITE);t.setTextSize(z);t.setPadding(dp(18),dp(14),dp(18),dp(14));return t;}
 Button btn(String s,View.OnClickListener l){Button b=new Button(this);b.setText(s);b.setOnClickListener(l);return b;}
 public void onCreate(Bundle b){super.onCreate(b);p=getSharedPreferences("save",0); load(); main();}
 void load(){String x=p.getString("chars","");if(!x.isEmpty())chars.addAll(Arrays.asList(x.split("\\|")));}
 void save(){p.edit().putString("chars",String.join("|",chars)).putString("active",p.getString("active","")).apply();}
 void base(String title){root=new LinearLayout(this);root.setOrientation(LinearLayout.VERTICAL);root.setBackgroundColor(Color.rgb(17,19,26)); root.addView(tv(title,28)); content=new LinearLayout(this);content.setOrientation(LinearLayout.VERTICAL);content.setPadding(dp(18),dp(8),dp(18),dp(18));root.addView(content,new LinearLayout.LayoutParams(-1,-1));setContentView(root);}
 void main(){base("QUIRK"); content.addView(tv("Offline Sandbox",17)); content.addView(tv("Local guest • No account required",14));
  if(!chars.isEmpty())content.addView(btn("Continue",v->game(p.getString("active",chars.get(0))))); content.addView(btn("New Game",v->newChar())); content.addView(btn("Select Character",v->select())); content.addView(btn("Settings",v->settings())); }
 void newChar(){final EditText e=new EditText(this);e.setHint("Character name");new AlertDialog.Builder(this).setTitle("New Character").setView(e).setPositiveButton("Create",(d,w)->{String n=e.getText().toString().trim();if(n.isEmpty())n="Character "+(chars.size()+1);chars.add(n);p.edit().putString("active",n).apply();save();game(n);}).setNegativeButton("Cancel",null).show();}
 void select(){base("Select Character"); if(chars.isEmpty())content.addView(tv("No local characters yet.",15)); for(String c:new ArrayList<>(chars)){LinearLayout row=new LinearLayout(this);row.addView(btn(c,v->game(c)),new LinearLayout.LayoutParams(0,-2,1));row.addView(btn("Delete",v->{chars.remove(c);save();select();}));content.addView(row);}content.addView(btn("New Game",v->newChar()));content.addView(btn("Back",v->main()));}
 void game(String c){p.edit().putString("active",c).apply();base("Outpost • "+c);content.addView(tv("Character: "+c,18));content.addView(tv("Level 1    Gems 100    Fuel 100",15));content.addView(tv("Local progression is active. Changes survive relaunch.",14));content.addView(btn("Earn 10 Gems",v->{int g=p.getInt("gems_"+c,100)+10;p.edit().putInt("gems_"+c,g).apply();game(c);}));content.addView(btn("Save",v->{save();Toast.makeText(this,"Saved locally",Toast.LENGTH_SHORT).show();}));content.addView(btn("Logout",v->select()));content.addView(btn("Main Menu",v->main()));}
 void settings(){base("Settings");content.addView(tv("Offline mode is always available. Network and Google login are not required for ordinary play.",15));content.addView(btn("Back",v->main()));}
}
