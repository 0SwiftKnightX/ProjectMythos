package com.ugen.playquirk;

import org.json.*;
import java.util.*;

public final class GameState {
    public static JSONObject create(String name) {
        JSONObject c=new JSONObject();
        try {
            c.put("id", UUID.randomUUID().toString());
            c.put("name", name);
            c.put("level",1).put("xp",0).put("gems",100).put("coins",500).put("fuel",100).put("health",100);
            c.put("appearance",0).put("equipped","Rustblade");
            c.put("inventory",new JSONArray(Arrays.asList("Rustblade","Traveler Boots","3 Iron Ore","2 Herbs")));
            c.put("equipment",new JSONObject().put("weapon","Rustblade").put("armor","Traveler Boots"));
            c.put("quests",new JSONArray(Arrays.asList("First Steps","Gather 3 Iron Ore","Explore the Outpost")));
            c.put("completed",new JSONArray());
            c.put("settings",new JSONObject().put("music",true).put("effects",true).put("offline",true));
        } catch(Exception ignored) {}
        return c;
    }
    private GameState() {}
}
