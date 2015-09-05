package com.cohenadair.anglerslog.model;

import com.cohenadair.anglerslog.model.user_defines.Catch;
import com.cohenadair.anglerslog.model.user_defines.Trip;

import java.util.ArrayList;
import java.util.Date;

/**
 * The Logbook class is a singleton class storing all of the user's log data.
 * @author Cohen Adair
 */
public class Logbook {

    //region Singleton Methods
    private static Logbook _sharedLogbook = new Logbook();

    public static Logbook getInstance() {
        return _sharedLogbook;
    }

    private Logbook() {

    }
    //endregion

    private String mName;
    private ArrayList<Catch> mCatches = new ArrayList<>();
    private ArrayList<Trip> mTrips = new ArrayList<>();

    //region Getters & Setters
    public String getName() {
        return mName;
    }

    public void setName(String name) {
        mName = name;
    }

    public ArrayList<Catch> getCatches() {
        return mCatches;
    }

    public void setCatches(ArrayList<Catch> catches) {
        mCatches = catches;
    }

    public ArrayList<Trip> getTrips() {
        return mTrips;
    }

    public void setTrips(ArrayList<Trip> trips) {
        mTrips = trips;
    }

    //endregion

    //region General Manipulation

    //endregion

    //region Catch Manipulation
    public boolean addCatch(Catch aCatch) {
        return mCatches.add(aCatch);
    }

    public boolean removeCatch(Catch aCatch) {
        return mCatches.remove(aCatch);
    }

    /**
     * Looks for existing catches with aDate.
     * @param aDate the date of the resulting catch.
     * @return the catch with aDate or null if no such catch exists.
     */
    public Catch catchDated(Date aDate) {
        for (Catch aCatch : mCatches) {
            if (aCatch.getDate().equals(aDate))
                return aCatch;
        }

        return null;
    }

    public Catch catchAtPos(int position) {
        return mCatches.get(position);
    }

    /**
     * @return the number of catches in the Logbook.
     */
    public int catchCount() {
        return mCatches.size();
    }
    //endregion

    //region Trip Manipulation
    public boolean addTrip(Trip aTrip) {
        return mTrips.add(aTrip);
    }

    public boolean removeTrip(Trip aTrip) {
        return mTrips.remove(aTrip);
    }

    public int tripCount() {
        return mTrips.size();
    }

    public Trip tripAtPos(int position) {
        return mTrips.get(position);
    }
    //endregion

}
