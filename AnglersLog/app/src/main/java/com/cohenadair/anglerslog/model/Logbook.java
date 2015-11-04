package com.cohenadair.anglerslog.model;

import android.content.Context;
import android.database.sqlite.SQLiteDatabase;
import android.support.annotation.Nullable;
import android.util.Log;

import com.cohenadair.anglerslog.database.LogbookHelper;
import com.cohenadair.anglerslog.database.QueryHelper;
import com.cohenadair.anglerslog.database.cursors.BaitCursor;
import com.cohenadair.anglerslog.database.cursors.CatchCursor;
import com.cohenadair.anglerslog.database.cursors.UserDefineCursor;
import com.cohenadair.anglerslog.model.user_defines.Bait;
import com.cohenadair.anglerslog.model.user_defines.BaitCategory;
import com.cohenadair.anglerslog.model.user_defines.Catch;
import com.cohenadair.anglerslog.model.user_defines.Species;
import com.cohenadair.anglerslog.model.user_defines.UserDefineObject;

import java.io.File;
import java.util.ArrayList;
import java.util.Random;
import java.util.UUID;

import static com.cohenadair.anglerslog.database.LogbookSchema.BaitCategoryTable;
import static com.cohenadair.anglerslog.database.LogbookSchema.BaitTable;
import static com.cohenadair.anglerslog.database.LogbookSchema.CatchPhotoTable;
import static com.cohenadair.anglerslog.database.LogbookSchema.CatchTable;
import static com.cohenadair.anglerslog.database.LogbookSchema.SpeciesTable;

/**
 * The Logbook class is a monostate class storing all of the user's log data.
 * @author Cohen Adair
 */
public class Logbook {

    private static final String TAG = "Logbook";

    private static SQLiteDatabase mDatabase;
    private static File mDatabaseFile;

    private Logbook() { }

    public static void init(Context context) {
        mDatabaseFile = context.getDatabasePath(LogbookHelper.DATABASE_NAME);
        init(context, new LogbookHelper(context).getWritableDatabase());
    }

    public static void init(Context context, SQLiteDatabase database) {
        mDatabaseFile = context.getDatabasePath(LogbookHelper.DATABASE_NAME);
        mDatabase = database;
        mDatabase.setForeignKeyConstraintsEnabled(true);
        QueryHelper.setDatabase(mDatabase);
        cleanDatabasePhotos();
    }

    //region Getters & Setters
    public static SQLiteDatabase getDatabase() {
        return mDatabase;
    }

    public static File getDatabaseFile() {
        return mDatabaseFile;
    }
    //endregion

    //region Miscellaneous
    /**
     * Gets a random Catch photo to use in the NavigationView.
     * @return A String representing a random photo name, or null if no photos exist.
     */
    @Nullable
    public static String getRandomCatchPhoto() {
        ArrayList<String> photoNames = QueryHelper.queryPhotos(CatchPhotoTable.NAME, null, null);

        if (photoNames.size() <= 0)
            return null;

        return photoNames.get(new Random().nextInt(photoNames.size()));
    }
    //endregion

    //region Catch Manipulation
    public static void cleanDatabasePhotos() {
        // TODO delete photos from BaitPhotoTable

        int numDeleted = mDatabase.delete(
                CatchPhotoTable.NAME,
                CatchPhotoTable.Columns.USER_DEFINE_ID + " NOT IN(SELECT " + CatchTable.Columns.ID + " FROM " + CatchTable.NAME + ")",
                null);

        Log.i(TAG, "Deleted " + numDeleted + " photos from the database.");
    }

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
        return QueryHelper.insertUserDefine(CatchTable.NAME, aCatch.getContentValues());
    }

    public static boolean removeCatch(UUID id) {
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
        return QueryHelper.queryUserDefines(QueryHelper.queryUserDefines(SpeciesTable.NAME, null, null), null);
    }

    public static Species getSpecies(UUID id) {
        UserDefineObject obj = QueryHelper.queryUserDefine(SpeciesTable.NAME, id, null);
        return (obj == null) ? null : new Species(obj);
    }

    public static boolean addSpecies(Species species) {
        return QueryHelper.insertUserDefine(SpeciesTable.NAME, species.getContentValues());
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
    //endregion

    //region BaitCategory Manipulation
    public static ArrayList<UserDefineObject> getBaitCategories() {
        return QueryHelper.queryUserDefines(QueryHelper.queryUserDefines(BaitCategoryTable.NAME, null, null), null);
    }

    public static BaitCategory getBaitCategory(UUID id) {
        UserDefineObject obj = QueryHelper.queryUserDefine(BaitCategoryTable.NAME, id, null);
        return (obj == null) ? null : new BaitCategory(obj);
    }

    public static boolean addBaitCategory(BaitCategory baitCategory) {
        return QueryHelper.insertUserDefine(BaitCategoryTable.NAME, baitCategory.getContentValues());
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

    public static boolean addBait(Bait bait) {
        return QueryHelper.insertUserDefine(BaitTable.NAME, bait.getContentValues());
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
    //endregion
}
