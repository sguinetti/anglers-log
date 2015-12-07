package com.cohenadair.anglerslog.model.user_defines;

import com.cohenadair.anglerslog.database.QueryHelper;
import com.cohenadair.anglerslog.database.cursors.FishingSpotCursor;
import com.cohenadair.anglerslog.database.cursors.UserDefineCursor;

import java.util.ArrayList;
import java.util.UUID;

import static com.cohenadair.anglerslog.database.LogbookSchema.FishingSpotTable;

/**
 * The Location object stores information on a single location, including many fishing spots
 * within that location.
 *
 * Created by Cohen Adair on 2015-11-03.
 */
public class Location extends UserDefineObject {

    public Location() {
        this("");
    }

    public Location(String name) {
        super(name);
    }

    public Location(Location location, boolean keepId) {
        super(location, keepId);
    }

    public Location(UserDefineObject obj) {
        super(obj);
    }

    public Location(UserDefineObject obj, boolean keepId) {
        super(obj, keepId);
    }

    //region Fishing Spot Manipulation
    public ArrayList<UserDefineObject> getFishingSpots() {
        return getFishingSpots(getId());
    }

    public void setFishingSpots(ArrayList<UserDefineObject> newFishingSpots) {
        ArrayList<UserDefineObject> oldFishingSpots = getFishingSpots();

        for (UserDefineObject oldSpot : oldFishingSpots)
            removeFishingSpot(oldSpot.getId());

        for (UserDefineObject newSpot : newFishingSpots)
            addFishingSpot((FishingSpot)newSpot);
    }

    public ArrayList<UserDefineObject> getFishingSpots(UUID id) {
        return QueryHelper.queryUserDefines(
            QueryHelper.queryUserDefines(FishingSpotTable.NAME,
            FishingSpotTable.Columns.LOCATION_ID + " = ?", new String[] { id.toString() }),
            new QueryHelper.UserDefineQueryInterface() {
                @Override
                public UserDefineObject getObject(UserDefineCursor cursor) {
                    return new FishingSpotCursor(cursor).getFishingSpot();
                }
            }
        );
    }

    public boolean addFishingSpot(FishingSpot fishingSpot) {
        return QueryHelper.insertQuery(FishingSpotTable.NAME, fishingSpot.getContentValues(getId()));
    }

    public boolean removeFishingSpot(UUID id) {
        return QueryHelper.deleteUserDefine(FishingSpotTable.NAME, id);
    }

    public int getFishingSpotCount() {
        return QueryHelper.queryCount(FishingSpotTable.NAME, FishingSpotTable.Columns.LOCATION_ID + " = ?", new String[]{idAsString()});
    }
    //endregion

}
