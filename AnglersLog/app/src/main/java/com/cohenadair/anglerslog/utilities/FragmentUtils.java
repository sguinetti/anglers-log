package com.cohenadair.anglerslog.utilities;

import android.app.Activity;
import android.support.annotation.Nullable;
import android.util.Log;
import android.widget.ArrayAdapter;

import com.cohenadair.anglerslog.fragments.CatchFragment;
import com.cohenadair.anglerslog.fragments.MyListFragment;
import com.cohenadair.anglerslog.fragments.TripFragment;
import com.cohenadair.anglerslog.model.user_defines.Catch;
import com.cohenadair.anglerslog.model.Logbook;
import com.cohenadair.anglerslog.model.user_defines.Trip;

/**
 * FragmentUtils is used for manipulating fragments throughout the application.
 * Created by Cohen Adair on 2015-09-03.
 */
public class FragmentUtils {

    /**
     * These constants represent the index for each fragment in the navigation drawer.
     * These ids are used to hide/show the correct fragments when a navigation item is clicked.
     * The actual string values for the navigation items can be found in the arrays resource files.
     */
    public static final int FRAGMENT_COUNT      = 6;

    public static final int FRAGMENT_CATCHES    = 0;
    public static final int FRAGMENT_TRIPS      = 1;
    public static final int FRAGMENT_GALLERY    = 2;
    public static final int FRAGMENT_STATS      = 3;
    public static final int FRAGMENT_LOCATIONS  = 4;
    public static final int FRAGMENT_BAITS      = 5;

    /**
     * Used to store previous selections for MyListFragment instances.
     */
    private static int[] mSelectionPositions = new int[FRAGMENT_COUNT];

    /**
     * Used to keep track of the current master-detail fragment pair.
     */
    private static int mCurrentFragmentId = FRAGMENT_CATCHES; // default starting fragment

    @Nullable
    public static FragmentInfo fragmentInfo(Activity activity, int fragmentId) {
        switch (fragmentId) {
            case FRAGMENT_CATCHES:
                return catchesFragmentInfo(activity);

            case FRAGMENT_TRIPS:
                return tripsFragmentInfo(activity);

            default:
                Log.e("FragmentUtils", "Invalid fragment id in fragmentInfo()");
                break;
        }

        return null;
    }

    public static int selectionPos(int fragmentId) {
        return mSelectionPositions[fragmentId];
    }

    public static void selectionPos(int fragmentId, int selectedPos) {
        mSelectionPositions[fragmentId] = selectedPos;
    }

    public static int getCurrentFragmentId() {
        return mCurrentFragmentId;
    }

    public static void setCurrentFragmentId(int currentFragmentId) {
        mCurrentFragmentId = currentFragmentId;
    }

    private static FragmentInfo catchesFragmentInfo(Activity activity) {
        FragmentInfo info = new FragmentInfo("fragment_catches");
        FragmentInfo detailInfo = new FragmentInfo("fragment_catch");

        detailInfo.setFragment(new CatchFragment());

        info.setDetailInfo(detailInfo);
        info.setArrayAdapter(new ArrayAdapter<Catch>(activity, android.R.layout.simple_list_item_1, Logbook.getInstance().getCatches()));
        info.setId(FRAGMENT_CATCHES);
        info.setFragment(MyListFragment.newInstance(info.getId()));

        return info;
    }

    private static FragmentInfo tripsFragmentInfo(Activity activity) {
        FragmentInfo info = new FragmentInfo("fragment_trips");
        FragmentInfo detailInfo = new FragmentInfo("fragment_trip");

        detailInfo.setFragment(new TripFragment());

        info.setDetailInfo(detailInfo);
        info.setArrayAdapter(new ArrayAdapter<Trip>(activity, android.R.layout.simple_list_item_1, Logbook.getInstance().getTrips()));
        info.setId(FRAGMENT_TRIPS);
        info.setFragment(MyListFragment.newInstance(info.getId()));

        return info;
    }

}