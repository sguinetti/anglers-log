package com.cohenadair.anglerslog.model;

import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.support.annotation.Nullable;

import com.cohenadair.anglerslog.database.LogbookHelper;
import com.cohenadair.anglerslog.database.QueryHelper;
import com.cohenadair.anglerslog.database.cursors.CatchCursor;
import com.cohenadair.anglerslog.database.cursors.UserDefineCursor;
import com.cohenadair.anglerslog.model.user_defines.Catch;
import com.cohenadair.anglerslog.model.user_defines.Species;
import com.cohenadair.anglerslog.model.user_defines.UserDefineObject;

import java.util.ArrayList;
import java.util.Date;
import java.util.UUID;

import static com.cohenadair.anglerslog.database.LogbookSchema.CatchTable;
import static com.cohenadair.anglerslog.database.LogbookSchema.SpeciesTable;

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
        mContext = context;
        mDatabase = new LogbookHelper(mContext).getWritableDatabase();
        QueryHelper.setDatabase(mDatabase);
    }

    public static void init(Context context, SQLiteDatabase database) {
        mContext = context;
        mDatabase = database;
        QueryHelper.setDatabase(mDatabase);
    }

    //region Getters & Setters
    public static SQLiteDatabase getDatabase() {
        return mDatabase;
    }
    //endregion

    //region Catch Manipulation
    public static ArrayList<UserDefineObject> getCatches() {
        ArrayList<UserDefineObject> catches = new ArrayList<>();
        CatchCursor cursor = QueryHelper.queryCatches(null, null);

        if (cursor.moveToFirst())
            while (!cursor.isAfterLast()) {
                catches.add(cursor.getCatch());
                cursor.moveToNext();
            }

        cursor.close();
        return catches;
    }

    @Nullable
    public static Catch getCatch(UUID id) {
        Catch aCatch = null;
        CatchCursor cursor = QueryHelper.queryCatches(CatchTable.Columns.ID + " = ?", new String[]{id.toString()});

        if (cursor.moveToFirst())
            aCatch = cursor.getCatch();

        cursor.close();
        return aCatch;
    }

    public static boolean catchExists(Date date) {
        Cursor cursor = QueryHelper.queryCatches(CatchTable.Columns.DATE + " = ?", new String[] { Long.toString(date.getTime()) });
        boolean result = cursor.getCount() > 0;
        cursor.close();
        return result;
    }

    public static boolean addCatch(Catch aCatch) {
        return mDatabase.insert(CatchTable.NAME, null, aCatch.getContentValues()) != -1;
    }

    public static boolean removeCatch(UUID id) {
        return mDatabase.delete(CatchTable.NAME, CatchTable.Columns.ID + " = ?", new String[]{id.toString()}) == 1;
    }

    public static boolean editCatch(UUID id, Catch newCatch) {
        newCatch.setId(id); // id needs to stay the same
        return mDatabase.update(CatchTable.NAME, newCatch.getContentValues(), CatchTable.Columns.ID + " = ?", new String[] { id.toString() }) == 1;
    }

    public static int getCatchCount() {
        return QueryHelper.queryCount(CatchTable.NAME);
    }
    //endregion

    //region Species Manipulation
    public static ArrayList<UserDefineObject> getSpecies() {
        ArrayList<UserDefineObject> species = new ArrayList<>();
        UserDefineCursor cursor = QueryHelper.queryUserDefines(SpeciesTable.NAME, null, null);

        if (cursor.moveToFirst())
            while (!cursor.isAfterLast()) {
                species.add(cursor.getObject());
                cursor.moveToNext();
            }

        cursor.close();
        return species;
    }

    @Nullable
    public static Species getSpecies(UUID id) {
        Species species = null;
        UserDefineCursor cursor = QueryHelper.queryUserDefines(SpeciesTable.NAME, CatchTable.Columns.ID + " = ?", new String[]{id.toString()});

        if (cursor.moveToFirst())
            species = new Species(cursor.getObject());

        cursor.close();
        return species;
    }

    public static boolean addSpecies(Species species) {
        return mDatabase.insert(SpeciesTable.NAME, null, species.getContentValues()) != -1;
    }

    public static boolean removeSpecies(UUID id) {
        return mDatabase.delete(SpeciesTable.NAME, SpeciesTable.Columns.ID + " = ?", new String[]{id.toString()}) == 1;
    }

    public static boolean editSpecies(UUID id, Species newSpecies) {
        newSpecies.setId(id); // id needs to stay the same
        return mDatabase.update(SpeciesTable.NAME, newSpecies.getContentValues(), SpeciesTable.Columns.ID + " = ?", new String[]{id.toString()}) == 1;
    }

    public static int getSpeciesCount() {
        return QueryHelper.queryCount(SpeciesTable.NAME);
    }

    /**
     * Iterates through all the species and removes ones where getShouldDelete() returns true.
     */
    public static void cleanSpecies() {
        ArrayList<UserDefineObject> species = getSpecies();
        for (int i = species.size() - 1; i >= 0; i--)
            if (species.get(i).getShouldDelete())
                removeSpecies(species.get(i).getId());
    }
    //endregion
}
