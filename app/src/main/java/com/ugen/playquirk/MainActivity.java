package com.ugen.playquirk;

import android.app.*;
import android.os.*;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.view.*;
import android.widget.*;
import org.json.*;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.util.*;

public class MainActivity extends Activity {
    static final String DIR="characters";
    LinearLayout root,body,nav;
    TextView title,status;
    String activeId="";
    JSONObject active;
    final ArrayList<JSONObject> characters=new ArrayList<>();

    int dp(int v){return (int)(v*getResources().getDisplayMetrics().density+.5f);}
    TextView text(String s,int size){TextView t=new TextView(this);t.setText(s);t.setTextColor(Color.WHITE);t.setTextSize(size);t.setPadding(dp(16),dp(10),dp(16),dp(10));return t;}
    Button button(String s,View.OnClickListener l){Button b=new Button(this);b.setText(s);b.setAllCaps(false);b.setOnClickListener(l);return b;}
    GradientDrawable bg(int c,int r){GradientDrawable g=new GradientDrawable();g.setColor(c);g.setCornerRadius(dp(r));return g;}

    @Override public void onCreate(Bundle b){
        super.onCreate(b);getWindow().setStatusBarColor(Color.rgb(10,12,18));
        loadAll();activeId=getPreferences(0).getString("active","");
        if(!activeId.isEmpty())active=find(activeId);
        showHome();
    }
    File charDir(){File d=new File(getFilesDir(),DIR);if(!d.exists())d.mkdirs();return d;}
    File charFile(String id){return new File(charDir(),id+".json");}
    void atomicWrite(File f,String s){
        File tmp=new File(f.getParent(),f.getName()+".tmp");
        try(FileOutputStream out=new FileOutputStream(tmp)){out.write(s.getBytes(StandardCharsets.UTF_8));out.flush();out.getFD().sync();}
        catch(Exception e){toast("Save failed.");return;}
        if(!tmp.renameTo(f)){try(FileInputStream in=new FileInputStream(tmp);FileOutputStream out=new FileOutputStream(f)){byte[] buf=new byte[8192];int n;while((n=in.read(buf))>0)out.write(buf,0,n);}catch(Exception ignored){}tmp.delete();}
    }
    void save(JSONObject c){if(c==null)return;atomicWrite(charFile(c.optString("id")),c.toString());getPreferences(0).edit().putString("active",activeId).commit();}
    void loadAll(){
        characters.clear();File[] fs=charDir().listFiles();if(fs==null)return;
        for(File f:fs)if(f.getName().endsWith(".json")&&!f.getName().endsWith(".tmp"))try{characters.add(new JSONObject(read(f)));}catch(Exception ignored){}
    }
    String read(File f)throws Exception{ByteArrayOutputStream out=new ByteArrayOutputStream();try(FileInputStream in=new FileInputStream(f)){byte[] b=new byte[8192];int n;while((n=in.read(b))>0)out.write(b,0,n);}return out.toString(StandardCharsets.UTF_8.name());}
    JSONObject find(String id){for(JSONObject c:characters)if(c.optString("id").equals(id))return c;return null;}

    JSONObject fresh(String name){return GameState.create(name);}

    void shell(String heading){
        root=new LinearLayout(this);root.setOrientation(LinearLayout.VERTICAL);root.setPadding(dp(14),dp(10),dp(14),dp(10));root.setBackgroundColor(Color.rgb(12,15,22));
        title=text(heading,26);title.setTypeface(Typeface.DEFAULT,Typeface.BOLD);root.addView(title);
        status=text("LOCAL GUEST • OFFLINE READY",12);status.setTextColor(Color.rgb(150,190,210));root.addView(status);
        body=new LinearLayout(this);body.setOrientation(LinearLayout.VERTICAL);ScrollView scroll=new ScrollView(this);scroll.addView(body);root.addView(scroll,new LinearLayout.LayoutParams(-1,0,1));
        nav=new LinearLayout(this);nav.setOrientation(LinearLayout.HORIZONTAL);nav.setPadding(0,dp(8),0,0);root.addView(nav,new LinearLayout.LayoutParams(-1,-2));setContentView(root);
        nav.addView(button("Home",v->showHome()),new LinearLayout.LayoutParams(0,-2,1));
        nav.addView(button("Characters",v->showCharacters()),new LinearLayout.LayoutParams(0,-2,1));
        nav.addView(button("Play",v->{if(active!=null)showGame();else newGame();}),new LinearLayout.LayoutParams(0,-2,1));
        nav.addView(button("Inventory",v->showInventory()),new LinearLayout.LayoutParams(0,-2,1));
        nav.addView(button("Settings",v->showSettings()),new LinearLayout.LayoutParams(0,-2,1));
    }
    void card(String s){TextView t=text(s,15);t.setBackground(bg(Color.rgb(24,29,40),18));body.addView(t,new LinearLayout.LayoutParams(-1,-2));}
    void gap(){Space s=new Space(this);body.addView(s,new LinearLayout.LayoutParams(1,dp(8)));}

    void showHome(){
        shell("QUIRK");
        card("Offline Adventure\nThis build is the foundation for the full game: persistent local characters, exploration, progression, inventory, quests and crafting.");
        gap();
        if(active!=null){card("ACTIVE CHARACTER\n"+active.optString("name")+" • Lv "+active.optInt("level",1)+" • "+active.optInt("gems",0)+" gems");body.addView(button("Continue",v->showGame()));}
        body.addView(button("New Game",v->newGame()));
        body.addView(button("Select Character",v->showCharacters()));
        body.addView(button("Import Template Character",v->importTemplate()));
        body.addView(button("Settings",v->showSettings()));
    }
    void newGame(){
        final EditText e=new EditText(this);e.setHint("Character name");
        new AlertDialog.Builder(this).setTitle("New local character").setMessage("Creates an independent local save.").setView(e).setPositiveButton("Create",(d,w)->{
            String n=e.getText().toString().trim();if(n.isEmpty())n="Character "+(characters.size()+1);
            JSONObject c=fresh(n);characters.add(c);active=c;activeId=c.optString("id");save(c);showGame();
        }).setNegativeButton("Cancel",null).show();
    }
    void showCharacters(){
        shell("Select Character");card(characters.isEmpty()?"No local characters yet. Create one below.":"Independent saves — switching never overwrites another character.");
        for(JSONObject c:new ArrayList<>(characters)){
            LinearLayout row=new LinearLayout(this);TextView info=text(c.optString("name")+"\nLv "+c.optInt("level",1)+" • "+c.optInt("coins",0)+" coins • "+c.optInt("gems",0)+" gems",15);
            info.setLayoutParams(new LinearLayout.LayoutParams(0,-2,1));row.addView(info);
            row.addView(button("Select",v->{active=c;activeId=c.optString("id");save(c);showGame();}));
            row.addView(button("Delete",v->deleteCharacter(c)));body.addView(row,new LinearLayout.LayoutParams(-1,-2));
        }
        body.addView(button("New Game",v->newGame()));
    }
    void deleteCharacter(JSONObject c){
        new AlertDialog.Builder(this).setTitle("Delete character?").setMessage("This permanently removes this local save.").setNegativeButton("Cancel",null).setPositiveButton("Delete",(d,w)->{
            charFile(c.optString("id")).delete();characters.remove(c);
            if(c.optString("id").equals(activeId)){active=null;activeId="";getPreferences(0).edit().remove("active").commit();}
            showCharacters();
        }).show();
    }

    void showGame(){
        if(active==null){showHome();return;}shell("Outpost • "+active.optString("name"));
        int xp=active.optInt("xp",0),lvl=active.optInt("level",1);
        card("LEVEL "+lvl+"   XP "+xp+"/"+(lvl*100)+"\nHEALTH "+active.optInt("health",100)+"   GEMS "+active.optInt("gems",0)+"   COINS "+active.optInt("coins",0)+"   FUEL "+active.optInt("fuel",0));
        gap();body.addView(button("Explore — enter the next encounter",v->explore()));
        body.addView(button("Rest — recover 20 health",v->rest()));
        body.addView(button("Craft Ironblade — spend 2 Iron Ore",v->craft()));
        body.addView(button("Cycle Appearance",v->{putInt(active,"appearance",(active.optInt("appearance",0)+1)%5);save(active);showGame();}));
        body.addView(button("Save Progress",v->{save(active);toast("Progress saved locally.");}));
        body.addView(button("Quests",v->showQuests()));body.addView(button("Inventory",v->showInventory()));
        body.addView(button("Logout → Character Selection",v->showCharacters()));
    }
    void explore(){
        if(active.optInt("fuel",0)<=0){toast("No fuel. Restores are available in Settings.");return;}
        try{
            int lvl=active.optInt("level",1),xp=active.optInt("xp",0)+35;
            active.put("xp",xp).put("coins",active.optInt("coins",0)+60).put("fuel",Math.max(0,active.optInt("fuel",0)-5));
            JSONArray inv=active.optJSONArray("inventory");if(inv==null){inv=new JSONArray();active.put("inventory",inv);}inv.put("Iron Ore");
            if(xp>=lvl*100){active.put("level",lvl+1).put("gems",active.optInt("gems",0)+25);toast("Level up! +25 gems.");}
            save(active);showGame();
        }catch(Exception ignored){toast("Encounter failed safely.");}
    }
    void rest(){putInt(active,"health",Math.min(100,active.optInt("health",100)+20));save(active);showGame();}
    void craft(){
        try{
            JSONArray inv=active.optJSONArray("inventory");if(inv==null){toast("No inventory.");return;}
            int count=0;for(int i=0;i<inv.length();i++)if(inv.optString(i).equals("Iron Ore"))count++;
            if(count<2){toast("Need 2 Iron Ore.");return;}
            JSONArray next=new JSONArray();int remaining=2;
            for(int i=0;i<inv.length();i++){String x=inv.optString(i);if(x.equals("Iron Ore")&&remaining>0)remaining--;else next.put(x);}
            next.put("Ironblade");active.put("inventory",next).put("equipped","Ironblade").put("equipment",new JSONObject().put("weapon","Ironblade").put("armor","Traveler Boots"));
            save(active);toast("Crafted and equipped Ironblade.");showGame();
        }catch(Exception ignored){toast("Crafting failed safely.");}
    }
    void showInventory(){
        shell("Inventory & Equipment");if(active==null){card("Select or create a character first.");return;}
        card("EQUIPPED WEAPON: "+active.optString("equipped")+"\nARMOR: "+active.optJSONObject("equipment").optString("armor","Traveler Boots")+"\nAPPEARANCE SLOT: "+active.optInt("appearance",0));
        JSONArray inv=active.optJSONArray("inventory");if(inv!=null)for(int i=0;i<inv.length();i++)body.addView(text("• "+inv.optString(i),15));
        body.addView(button("Save Inventory",v->{save(active);toast("Inventory saved.");}));
    }
    void showQuests(){
        shell("Quests");if(active==null){card("No active character.");return;}
        JSONArray q=active.optJSONArray("quests"),done=active.optJSONArray("completed");for(int i=0;i<q.length();i++){
            String s=q.optString(i);boolean complete=false;for(int j=0;j<done.length();j++)if(done.optString(j).equals(s))complete=true;
            body.addView(button((complete?"✓ ":"○ ")+s,v->completeQuest(s)));
        }
    }
    void completeQuest(String s){
        try{JSONArray d=active.optJSONArray("completed");if(d==null){d=new JSONArray();active.put("completed",d);}
            for(int i=0;i<d.length();i++)if(d.optString(i).equals(s)){toast("Already complete.");return;}
            d.put(s);active.put("coins",active.optInt("coins",0)+100);save(active);showQuests();
        }catch(Exception ignored){}
    }
    void showSettings(){
        shell("Settings");card("OFFLINE MODE\nNo authentication or network dependency is required for ordinary play. Saves are private to this app installation.");
        body.addView(button("Restore 100 Fuel",v->{if(active!=null){putInt(active,"fuel",100);save(active);toast("Fuel restored locally.");}}));
        body.addView(button("Repair / Re-read local saves",v->{loadAll();active=find(activeId);toast("Local saves reloaded.");showHome();}));
        body.addView(button("Template policy",v->new AlertDialog.Builder(this).setTitle("Separate template").setMessage("The template is imported as its own character record and does not become the clean first-run user save.").setPositiveButton("OK",null).show()));
    }
    void importTemplate(){
        JSONObject t=fresh("Template • Known Good");try{t.put("template",true).put("level",5).put("xp",350).put("gems",500).put("coins",2500);t.optJSONArray("inventory").put("Ironblade").put("Rare Core");}catch(Exception ignored){}
        characters.add(t);active=t;activeId=t.optString("id");save(t);showCharacters();
    }
    void putInt(JSONObject c,String key,int value){try{c.put(key,value);}catch(Exception ignored){}}
    void toast(String s){Toast.makeText(this,s,Toast.LENGTH_SHORT).show();}
}
