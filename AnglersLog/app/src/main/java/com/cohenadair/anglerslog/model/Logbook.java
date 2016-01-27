package com.cohenadair.anglerslog.model;

import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.support.annotation.Nullable;
import android.util.Log;

import com.cohenadair.anglerslog.database.LogbookHelper;
import com.cohenadair.anglerslog.database.QueryHelper;
import com.cohenadair.anglerslog.database.cursors.AnglerCursor;
import com.cohenadair.anglerslog.database.cursors.BaitCategoryCursor;
import com.cohenadair.anglerslog.database.cursors.BaitCursor;
import com.cohenadair.anglerslog.database.cursors.CatchCursor;
import com.cohenadair.anglerslog.database.cursors.FishingMethodCursor;
import com.cohenadair.anglerslog.database.cursors.FishingSpotCursor;
import com.cohenadair.anglerslog.database.cursors.LocationCursor;
import com.cohenadair.anglerslog.database.cursors.SpeciesCursor;
import com.cohenadair.anglerslog.database.cursors.TripCursor;
import com.cohenadair.anglerslog.database.cursors.UserDefineCursor;
import com.cohenadair.anglerslog.database.cursors.WaterClarityCursor;
import com.cohenadair.anglerslog.model.user_defines.Angler;
import com.cohenadair.anglerslog.model.user_defines.Bait;
import com.cohenadair.anglerslog.model.user_defines.BaitCategory;
import com.cohenadair.anglerslog.model.user_defines.Catch;
import com.cohenadair.anglerslog.model.user_defines.FishingMethod;
import com.cohenadair.anglerslog.model.user_defines.FishingSpot;
import com.cohenadair.anglerslog.model.user_defines.Location;
import com.cohenadair.anglerslog.model.user_defines.Species;
import com.cohenadair.anglerslog.model.user_defines.Trip;
import com.cohenadair.anglerslog.model.user_defines.UserDefineObject;
import com.cohenadair.anglerslog.model.user_defines.WaterClarity;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Random;
import java.util.UUID;

import static com.cohenadair.anglerslog.database.LogbookSchema.AnglerTable;
import static com.cohenadair.anglerslog.database.LogbookSchema.BaitCategoryTable;
import static com.cohenadair.anglerslog.database.LogbookSchema.BaitTable;
import static com.cohenadair.anglerslog.database.LogbookSchema.CatchPhotoTable;
import static com.cohenadair.anglerslog.database.LogbookSchema.CatchTable;
import static com.cohenadair.anglerslog.database.LogbookSchema.FishingMethodTable;
import static com.cohenadair.anglerslog.database.LogbookSchema.FishingSpotTable;
import static com.cohenadair.anglerslog.database.LogbookSchema.LocationTable;
import static com.cohenadair.anglerslog.database.LogbookSchema.SpeciesTable;
import static com.cohenadair.anglerslog.database.LogbookSchema.TripTable;
import static com.cohenadair.anglerslog.database.LogbookSchema.WaterClarityTable;

/**
 * The Logbook class is a monostate class storing all of the user's log data.
 * @author Cohen Adair
 */
public class Logbook {

    private static final String TAG = "Logbook";

    private static SQLiteDatabase mDatabase;
    private static Context mContext;

    private Logbook() { }

    public static void init(Context context) {
        init(context, new LogbookHelper(context).getWritableDatabase());
        setDefaults();
    }

    public static void init(Context context, SQLiteDatabase database) {
        mContext = context;
        mDatabase = database;
        mDatabase.setForeignKeyConstraintsEnabled(true);
        QueryHelper.setDatabase(mDatabase);
        cleanDatabasePhotos();
    }

    public static void initForTesting(Context context, SQLiteDatabase database) {
        init(context, database);
    }

    /**
     * Set some default UserDefineObjects if there aren't any.
     */
    private static void setDefaults() {
        if (getBaitCategoryCount() <= 0) {
            Log.d(TAG, "Adding default bait category");

            addBaitCategory(new BaitCategory("Woolly Bugger"));
            addBaitCategory(new BaitCategory("Yarn Fly"));
            addBaitCategory(new BaitCategory("Bead"));
        }

        if (getSpeciesCount() <= 0) {
            Log.d(TAG, "Adding default species.");

            addSpecies(new Species("Steelhead"));
            addSpecies(new Species("Pike"));
            addSpecies(new Species("Bass - Smallmouth"));
            addSpecies(new Species("Salmon - Coho"));
        }
    }

    //region Getters & Setters
    public static SQLiteDatabase getDatabase() {
        return mDatabase;
    }
    //endregion

    /**
     * Gets a random Catch photo to use in the NavigationView.
     * @return A String representing a random photo name, or null if no photos exist.
     */
    @Nullable
    public static String getRandomCatchPhoto() {
        ArrayList<String> photoNames = QueryHelper.queryPhotos(CatchPhotoTable.NAME, null);

        if (photoNames.size() <= 0)
            return null;

        return photoNames.get(new Random().nextInt(photoNames.size()));
    }

    /**
     * Deletes all database entries for photos that aren't associated with any UserDefineObject
     * instances.
     */
    public static void cleanDatabasePhotos() {
        // TODO delete photos from BaitPhotoTable

        int numDeleted = mDatabase.delete(
                CatchPhotoTable.NAME,
                CatchPhotoTable.Columns.USER_DEFINE_ID + " NOT IN(SELECT " + CatchTable.Columns.ID + " FROM " + CatchTable.NAME + ")",
                null);

        Log.i(TAG, "Deleted " + numDeleted + " photos from the database.");
    }

    //region Catch Manipulation
    public static ArrayList<UserDefineObject> getCatches() {
        return QueryHelper.queryUserDefines(QueryHelper.queryCatches(null, null), new QueryHelper.UserDefineQueryInterface() {
            @Override
            public UserDefineObject getObject(UserDefineCursor cursor) {
                return new CatchCursor(cursor).getCatch();
            }
        });
    }

    public static Catch getCatch(UUID id) {
        UserDefineObject obj = QueryHelper.queryUserDefine(CatchTable.NAME, id, new QueryHelper.UserDefineQueryInterface() {
            @Override
            public UserDefineObject getObject(UserDefineCursor cursor) {
                return new CatchCursor(cursor).getCatch();
            }
        });

        return (obj == null) ? null : (Catch)obj;
    }

    public static boolean addCatch(Catch aCatch) {
        return QueryHelper.insertQuery(CatchTable.NAME, aCatch.getContentValues());
    }

    public static boolean removeCatch(UUID id) {
        Catch aCatch = Logbook.getCatch(id);
        aCatch.removeDatabaseProperties();
        return QueryHelper.deleteUserDefine(CatchTable.NAME, id);
    }

    public static boolean editCatch(UUID id, Catch newCatch) {
        return QueryHelper.updateUserDefine(CatchTable.NAME, newCatch.getContentValues(), id);
    }

    public static int getCatchCount() {
        return QueryHelper.queryCount(CatchTable.NAME);
    }
    //endregion

    //region Species Manipulation
    public static ArrayList<UserDefineObject> getSpecies() {
        return QueryHelper.queryUserDefines(QueryHelper.queryUserDefines(SpeciesTable.NAME, null, null), new QueryHelper.UserDefineQueryInterface() {
            @Override
            public UserDefineObject getObject(UserDefineCursor cursor) {
                return new SpeciesCursor(cursor).getSpecies();
            }
        });
    }

    public static Species getSpecies(UUID id) {
        UserDefineObject obj = QueryHelper.queryUserDefine(SpeciesTable.NAME, id, new QueryHelper.UserDefineQueryInterface() {
            @Override
            public UserDefineObject getObject(UserDefineCursor cursor) {
                return new SpeciesCursor(cursor).getSpecies();
            }
        });

        return (obj == null) ? null : (Species)obj;
    }

    public static boolean addSpecies(Species species) {
        return QueryHelper.insertQuery(SpeciesTable.NAME, species.getContentValues());
    }

    public static boolean removeSpecies(UUID id) {
        return QueryHelper.deleteUserDefine(SpeciesTable.NAME, id);
    }

    public static boolean editSpecies(UUID id, Species newSpecies) {
        return QueryHelper.updateUserDefine(SpeciesTable.NAME, newSpecies.getContentValues(), id);
    }

    public static int getSpeciesCount() {
        return QueryHelper.queryCount(SpeciesTable.NAME);
    }

    public static ArrayList<Stats.Quantity> getSpeciesCaughtCount() {
        return getCatchQuantity(getSpecies(), new OnQueryQuantityListener() {
            @Override
            public int query(UserDefineObject obj) {
                return QueryHelper.queryUserDefineCatchCount(obj, CatchTable.Columns.SPECIES_ID);
            }
        });
    }
    //endregion

    //region BaitCategory Manipulation
    public static ArrayList<UserDefineObject> getBaitCategories() {
        return QueryHelper.queryUserDefines(QueryHelper.queryUserDefines(BaitCategoryTable.NAME, null, null), new QueryHelper.UserDefineQueryInterface() {
            @Override
            public UserDefineObject getObject(UserDefineCursor cursor) {
                return new BaitCategoryCursor(cursor).getBaitCategory();
            }
        });
    }

    public static BaitCategory getBaitCategory(UUID id) {
        UserDefineObject obj = QueryHelper.queryUserDefine(BaitCategoryTable.NAME, id, new QueryHelper.UserDefineQueryInterface() {
            @Override
            public UserDefineObject getObject(UserDefineCursor cursor) {
                return new BaitCategoryCursor(cursor).getBaitCategory();
            }
        });

        return (obj == null) ? null : (BaitCategory)obj;
    }

    public static boolean addBaitCategory(BaitCategory baitCategory) {
        return QueryHelper.insertQuery(BaitCategoryTable.NAME, baitCategory.getContentValues());
    }

    public static boolean removeBaitCategory(UUID id) {
        return QueryHelper.deleteUserDefine(BaitCategoryTable.NAME, id);
    }

    public static boolean editBaitCategory(UUID id, BaitCategory newBaitCategory) {
        return QueryHelper.updateUserDefine(BaitCategoryTable.NAME, newBaitCategory.getContentValues(), id);
    }

    public static int getBaitCategoryCount() {
        return QueryHelper.queryCount(BaitCategoryTable.NAME);
    }
    //endregion

    //region Bait Manipulation
    public static ArrayList<UserDefineObject> getBaits() {
        return QueryHelper.queryUserDefines(QueryHelper.queryBaits(null, null), new QueryHelper.UserDefineQueryInterface() {
            @Override
            public UserDefineObject getObject(UserDefineCursor cursor) {
                return new BaitCursor(cursor).getBait();
            }
        });
    }

    public static Bait getBait(UUID id) {
        UserDefineObject obj = QueryHelper.queryUserDefine(BaitTable.NAME, id, new QueryHelper.UserDefineQueryInterface() {
            @Override
            public UserDefineObject getObject(UserDefineCursor cursor) {
                return new BaitCursor(cursor).getBait();
            }
        });

        return (obj == null) ? null : (Bait)obj;
    }

    /**
     * Checks to see if the Bait already exists in the database.
     *
     * @param bait The Bait object to look for.
     * @return True if the Bait exists; false otherwise.
     */
    public static boolean baitExists(Bait bait) {
        Cursor cursor = mDatabase.query(BaitTable.NAME, null, BaitTable.Columns.CATEGORY_ID + " = ? AND " + BaitTable.Columns.NAME + " = ?", new String[]{bait.getCategoryId().toString(), bait.getName()}, null, null, null);
        return QueryHelper.queryHasResults(cursor);
    }

    public static boolean addBait(Bait bait) {
        return QueryHelper.insertQuery(BaitTable.NAME, bait.getContentValues());
    }

    public static boolean removeBait(UUID id) {
        return QueryHelper.deleteUserDefine(BaitTable.NAME, id);
    }

    public static boolean editBait(UUID id, Bait newBait) {
        return QueryHelper.updateUserDefine(BaitTable.NAME, newBait.getContentValues(), id);
    }

    public static int getBaitCount() {
        return QueryHelper.queryCount(BaitTable.NAME);
    }

    /**
     * Gets an ordered array of bait categories with their respective baits.
     *
     * @return An ArrayList of BaitCategory and Bait objects.
     */
    public static ArrayList<UserDefineObject> getBaitsAndCategories() {
        ArrayList<UserDefineObject> result = new ArrayList<>();
        ArrayList<UserDefineObject> categories = getBaitCategories();
        ArrayList<UserDefineObject> baits = getBaits();

        for (UserDefineObject category : categories) {
            result.add(category);

            for (UserDefineObject bait : baits)
                if (((Bait)bait).getCategoryId().equals(category.getId()))
                    result.add(bait);
        }

        return result;
    }

    public static ArrayList<Stats.Quantity> getBaitUsedCount() {
        return getCatchQuantity(getBaits(), new OnQueryQuantityListener() {
            @Override
            public int query(UserDefineObject obj) {
                return QueryHelper.queryUserDefineCatchCount(obj, CatchTable.Columns.BAIT_ID);
            }
        });
    }
    //endregion

    //region Location Manipulation
    public static ArrayList<UserDefineObject> getLocations() {
        return QueryHelper.queryUserDefines(QueryHelper.queryUserDefines(LocationTable.NAME, null, null), new QueryHelper.UserDefineQueryInterface() {
            @Override
            public UserDefineObject getObject(UserDefineCursor cursor) {
                return new LocationCursor(cursor).getLocation();
            }
        });
    }

    public static Location getLocation(UUID id) {
        UserDefineObject obj = QueryHelper.queryUserDefine(LocationTable.NAME, id, new QueryHelper.UserDefineQueryInterface() {
            @Override
            public UserDefineObject getObject(UserDefineCursor cursor) {
                return new LocationCursor(cursor).getLocation();
            }
        });

        return (obj == null) ? null : (Location)obj;
    }

    public static FishingSpot getFishingSpot(UUID id) {
        UserDefineObject obj = QueryHelper.queryUserDefine(FishingSpotTable.NAME, id, new QueryHelper.UserDefineQueryInterface() {
            @Override
            public UserDefineObject getObject(UserDefineCursor cursor) {
                return new FishingSpotCursor(cursor).getFishingSpot();
            }
        });

        return (obj == null) ? null : (FishingSpot)obj;
    }

    /**
     * Checks to see if the Location already exists in the database.
     *
     * @param location The Location object to look for.
     * @return True if the Location exists; false otherwise.
     */
    public static boolean locationExists(Location location) {
        Cursor cursor = mDatabase.query(LocationTable.NAME, null, LocationTable.Columns.NAME + " = ?", new String[]{location.getName()}, null, null, null);
        return QueryHelper.queryHasResults(cursor);
    }

    public static boolean addLocation(Location location) {
        return QueryHelper.insertQuery(LocationTable.NAME, location.getContentValues());
    }

    public static boolean removeLocation(UUID id) {
        return getLocation(id).removeAllFishingSpots() && QueryHelper.deleteUserDefine(LocationTable.NAME, id);
    }

    public static boolean editLocation(UUID id, Location newLocation) {
        return QueryHelper.updateUserDefine(LocationTable.NAME, newLocation.getContentValues(), id);
    }

    public static int getLocationCount() {
        return QueryHelper.queryCount(LocationTable.NAME);
    }

    public static ArrayList<Stats.Quantity> getLocationCatchCount() {
        return getCatchQuantity(getLocations(), new OnQueryQuantityListener() {
            @Override
            public int query(UserDefineObject obj) {
                return QueryHelper.queryLocationCatchCount((Location)obj);
            }
        });
    }
    //endregion

    //region WaterClarity Manipulation
    public static ArrayList<UserDefineObject> getWaterClarities() {
        return QueryHelper.queryUserDefines(QueryHelper.queryUserDefines(WaterClarityTable.NAME, null, null), new QueryHelper.UserDefineQueryInterface() {
            @Override
            public UserDefineObject getObject(UserDefineCursor cursor) {
                return new WaterClarityCursor(cursor).getWaterClarity();
            }
        });
    }

    public static WaterClarity getWaterClarity(UUID id) {
        UserDefineObject obj = QueryHelper.queryUserDefine(WaterClarityTable.NAME, id, new QueryHelper.UserDefineQueryInterface() {
            @Override
            public UserDefineObject getObject(UserDefineCursor cursor) {
                return new WaterClarityCursor(cursor).getWaterClarity();
            }
        });

        return (obj == null) ? null : (WaterClarity)obj;
    }

    public static boolean addWaterClarity(WaterClarity clarity) {
        return QueryHelper.insertQuery(WaterClarityTable.NAME, clarity.getContentValues());
    }

    public static boolean removeWaterClarity(UUID id) {
        return QueryHelper.deleteUserDefine(WaterClarityTable.NAME, id);
    }

    public static boolean editWaterClarity(UUID id, WaterClarity newClarity) {
        return QueryHelper.updateUserDefine(WaterClarityTable.NAME, newClarity.getContentValues(), id);
    }

    public static int getWaterClarityCount() {
        return QueryHelper.queryCount(WaterClarityTable.NAME);
    }
    //endregion

    //region FishingMethod Manipulation
    public static ArrayList<UserDefineObject> getFishingMethods() {
        return QueryHelper.queryUserDefines(QueryHelper.queryUserDefines(FishingMethodTable.NAME, null, null), new QueryHelper.UserDefineQueryInterface() {
            @Override
            public UserDefineObject getObject(UserDefineCursor cursor) {
                return new FishingMethodCursor(cursor).getFishingMethod();
            }
        });
    }

    public static FishingMethod getFishingMethod(UUID id) {
        UserDefineObject obj = QueryHelper.queryUserDefine(FishingMethodTable.NAME, id, new QueryHelper.UserDefineQueryInterface() {
            @Override
            public UserDefineObject getObject(UserDefineCursor cursor) {
                return new FishingMethodCursor(cursor).getFishingMethod();
            }
        });

        return (obj == null) ? null : (FishingMethod)obj;
    }

    public static boolean addFishingMethod(FishingMethod method) {
        return QueryHelper.insertQuery(FishingMethodTable.NAME, method.getContentValues());
    }

    public static boolean removeFishingMethod(UUID id) {
        return QueryHelper.deleteUserDefine(FishingMethodTable.NAME, id);
    }

    public static boolean editFishingMethod(UUID id, FishingMethod newFishingMethod) {
        return QueryHelper.updateUserDefine(FishingMethodTable.NAME, newFishingMethod.getContentValues(), id);
    }

    public static int getFishingMethodCount() {
        return QueryHelper.queryCount(FishingMethodTable.NAME);
    }
    //endregion

    //region Angler Manipulation
    public static ArrayList<UserDefineObject> getAnglers() {
        return QueryHelper.queryUserDefines(QueryHelper.queryUserDefines(AnglerTable.NAME, null, null), new QueryHelper.UserDefineQueryInterface() {
            @Override
            public UserDefineObject getObject(UserDefineCursor cursor) {
                return new AnglerCursor(cursor).getAngler();
            }
        });
    }

    public static Angler getAngler(UUID id) {
        UserDefineObject obj = QueryHelper.queryUserDefine(AnglerTable.NAME, id, new QueryHelper.UserDefineQueryInterface() {
            @Override
            public UserDefineObject getObject(UserDefineCursor cursor) {
                return new AnglerCursor(cursor).getAngler();
            }
        });

        return (obj == null) ? null : (Angler)obj;
    }

    public static boolean addAngler(Angler angler) {
        return QueryHelper.insertQuery(AnglerTable.NAME, angler.getContentValues());
    }

    public static boolean removeAngler(UUID id) {
        return QueryHelper.deleteUserDefine(AnglerTable.NAME, id);
    }

    public static boolean editAngler(UUID id, Angler newAngler) {
        return QueryHelper.updateUserDefine(AnglerTable.NAME, newAngler.getContentValues(), id);
    }

    public static int getAnglerCount() {
        return QueryHelper.queryCount(AnglerTable.NAME);
    }
    //endregion

    //region Trip Manipulation
    /**
     * Checks to see if a trip with the given date range already exists in the database.
     *
     * @param trip The {@link Trip} object to look for.
     * @return True if the trip exists, false otherwise.
     */
    public static boolean tripExists(Trip trip) {
        ArrayList<UserDefineObject> trips = getTrips();

        for (UserDefineObject object : trips)
            if (trip.overlapsTrip((Trip)object))
                return true;

        return false;
    }

    public static ArrayList<UserDefineObject> getTrips() {
        return QueryHelper.queryUserDefines(QueryHelper.queryUserDefines(TripTable.NAME, null, null), new QueryHelper.UserDefineQueryInterface() {
            @Override
            public UserDefineObject getObject(UserDefineCursor cursor) {
                return new TripCursor(cursor).getTrip();
            }
        });
    }

    public static Trip getTrip(UUID id) {
        UserDefineObject obj = QueryHelper.queryUserDefine(TripTable.NAME, id, new QueryHelper.UserDefineQueryInterface() {
            @Override
            public UserDefineObject getObject(UserDefineCursor cursor) {
                return new TripCursor(cursor).getTrip();
            }
        });

        return (obj == null) ? null : (Trip)obj;
    }

    public static boolean addTrip(Trip trip) {
        return QueryHelper.insertQuery(TripTable.NAME, trip.getContentValues());
    }

    public static boolean removeTrip(UUID id) {
        Trip trip = Logbook.getTrip(id);
        trip.removeDatabaseProperties();
        return QueryHelper.deleteUserDefine(TripTable.NAME, id);
    }

    public static boolean editTrip(UUID id, Trip newTrip) {
        return QueryHelper.updateUserDefine(TripTable.NAME, newTrip.getContentValues(), id);
    }

    public static int getTripCount() {
        return QueryHelper.queryCount(TripTable.NAME);
    }
    //endregion

    //region Common Manipulation
    private interface OnQueryQuantityListener {
        int query(UserDefineObject obj);
    }

    /**
     * Gets an array of {@link com.cohenadair.anglerslog.model.Stats.Quantity} objects that
     * represent the quantity of catches associated with the given {@link UserDefineObject}s.
     *
     * @param objects The objects to check for {@link Catch} association.
     * @param listener The listener for querying the database.
     * @return An array of sorted UserDefineObject stat quantities.
     */
    private static ArrayList<Stats.Quantity> getCatchQuantity(ArrayList<UserDefineObject> objects, OnQueryQuantityListener listener) {
        ArrayList<Stats.Quantity> list = new ArrayList<>();

        for (UserDefineObject obj : objects)
            list.add(new Stats.Quantity(obj.getDisplayName(), listener.query(obj)));

        Collections.sort(list, new Stats.QuantityComparator());
        return list;
    }
    //endregion
}
