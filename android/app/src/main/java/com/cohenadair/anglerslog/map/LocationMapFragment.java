package com.cohenadair.anglerslog.map;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.support.annotation.NonNull;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.LinearLayout;
import android.widget.ListView;
import android.widget.TextView;

import com.cohenadair.anglerslog.R;
import com.cohenadair.anglerslog.fragments.DraggableMapFragment;
import com.cohenadair.anglerslog.fragments.MasterFragment;
import com.cohenadair.anglerslog.model.Logbook;
import com.cohenadair.anglerslog.model.user_defines.UserDefineObject;
import com.cohenadair.anglerslog.model.utilities.SortingUtils;
import com.cohenadair.anglerslog.model.utilities.UserDefineArrays;
import com.cohenadair.anglerslog.utilities.FishingSpotMarkerManager;
import com.cohenadair.anglerslog.utilities.Utils;
import com.cohenadair.anglerslog.utilities.ViewUtils;
import com.google.android.gms.maps.GoogleMap;

import java.util.ArrayList;
import java.util.UUID;

/**
 * A LocationMapFragment displays an interactive map of all the user's fishing spots.
 * @author Cohen Adair
 */
public class LocationMapFragment extends MasterFragment {

    private static final String TAG_MAP = "LocationMapMap";

    private ListView mSearchList;
    private TextView mSearchMessage;
    private LinearLayout mSearchContainer;
    private LinearLayout mMapContainer;
    private DraggableMapFragment mMapFragment;

    private FishingSpotMarkerManager mMarkerManager;
    private ArrayList<UserDefineObject> mFishingSpots;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_map, container, false);

        mMapContainer = (LinearLayout)view.findViewById(R.id.location_map_container);
        mFishingSpots = UserDefineArrays.sort(Logbook.getAllFishingSpots(),
                SortingUtils.byDisplayName(getContext()));
        initMapFragment();

        mSearchContainer = (LinearLayout)view.findViewById(R.id.search_result_container);
        mSearchContainer.bringToFront();
        hideSearchContainer();

        mSearchMessage = (TextView)view.findViewById(R.id.search_result_text_view);
        mSearchList = (ListView)view.findViewById(R.id.search_list_view);

        setSearchInteractionListener(getSearchInteractionListener());

        return view;
    }

    @Override
    public void onCreateOptionsMenu(Menu menu, MenuInflater inflater) {
        inflater.inflate(R.menu.menu_map, menu);
        super.onCreateOptionsMenu(menu, inflater);
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        if (mMapFragment.getGoogleMap() == null)
            return super.onOptionsItemSelected(item);

        int id = item.getItemId();

        if (id == R.id.action_zoom) {
            mMarkerManager.showAllMarkers();
            return true;
        }

        if (id == R.id.action_share) {
            onClickShareMap();
            return true;
        }

        return (id == R.id.action_search) || super.onOptionsItemSelected(item);
    }

    @Override
    public void onResume() {
        super.onResume();

        // so the map isn't resized when the soft keyboard is shown
        getActivity().getWindow().setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_NOTHING);
    }

    @Override
    public void onPause() {
        super.onPause();

        // reset to default
        getActivity().getWindow().setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE);
    }

    @Override
    public void updateInterface() {
        updateMap();
    }

    private SearchInteractionListener getSearchInteractionListener() {
        return new SearchInteractionListener() {
            @Override
            public void onIconClicked() {
                // disable search if there's no map
                if (mMapFragment.getGoogleMap() == null) {
                    iconifySearchView();
                    return;
                }

                setMenuItemsVisibility(false);
                setSearchQueryHint(String.format(getString(R.string.search),
                        getString(R.string.locations_lowercase)));
                resetSearchViews();
            }

            @Override
            public void onClose() {
                hideSearchContainer();
            }

            @Override
            public void onTextSubmit(String query) {
                showSearchResults(query);
            }

            @Override
            public void onTextChanged(String newText) {
                if (newText.isEmpty()) {
                    resetSearchViews();
                }
            }

            @Override
            public void onReset() {

            }
        };
    }

    private void initMapFragment() {
        // check to see if the map fragment already exists
        mMapFragment = (DraggableMapFragment)getChildFragmentManager().findFragmentByTag(TAG_MAP);

        if (mMapFragment == null) {
            mMapFragment = DraggableMapFragment.newInstance(true, false);

            getChildFragmentManager()
                    .beginTransaction()
                    .add(R.id.location_map_container, mMapFragment, TAG_MAP)
                    .commit();
        }

        mMapFragment.getMapAsync(new DraggableMapFragment.InteractionListener() {
            @Override
            public void onMapReady(GoogleMap map) {
                LocationMapFragment.this.onMapReady();
            }

            @Override
            public void onLocationUpdate(android.location.Location location) {

            }
        });
    }

    private void onMapReady() {
        mMarkerManager = new FishingSpotMarkerManager(getContext(), mMapContainer, mMapFragment.getGoogleMap());
        mMarkerManager.setShowFishingSpotLocation(true);
        updateMap();
    }

    private void updateMap() {
        if (mMapFragment.getGoogleMap() == null || mFishingSpots.size() <= 0)
            return;

        mMarkerManager.setFishingSpots(mFishingSpots);
        mMarkerManager.updateMarkers();
        mMarkerManager.showAllMarkers();
    }

    private void resetSearchViews() {
        ViewUtils.setVisibility(mSearchContainer, true);
        ViewUtils.setVisibility(mSearchList, true);
        ViewUtils.setVisibility(mSearchMessage, false);

        if (!mMarkerManager.hasMarkers()) {
            mSearchMessage.setText(R.string.map_no_search);
            ViewUtils.setVisibility(mSearchMessage, true);
        }

        // initially show all fishing spots
        mSearchList.setAdapter(getSearchAdapter(mFishingSpots));
        mSearchList.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
                selectSearchItem(mFishingSpots.get(position).getId());
                iconifySearchView();
            }
        });
    }

    private void hideSearchContainer() {
        ViewUtils.setVisibility(mSearchContainer, false);
    }

    private void showSearchResults(String query) {
        final ArrayList<UserDefineObject> filtered = UserDefineArrays.search(getContext(), mFishingSpots, query);

        // if there are no results, notify the user
        if (filtered.size() <= 0) {
            mSearchMessage.setText(R.string.no_search_results);
            ViewUtils.setVisibility(mSearchMessage, true);
            ViewUtils.setVisibility(mSearchList, false);
            return;
        }

        // update adapter and event for the filtered list
        mSearchList.setAdapter(getSearchAdapter(filtered));
        mSearchList.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
                selectSearchItem(filtered.get(position).getId());
                iconifySearchView();
            }
        });

        ViewUtils.setVisibility(mSearchList, true);
        ViewUtils.setVisibility(mSearchMessage, false);
    }

    private void selectSearchItem(UUID selectedId) {
        for (int i = 0 ; i < mFishingSpots.size(); i++)
            if (mFishingSpots.get(i).getId().equals(selectedId)) {
                mMarkerManager.showInfoWindowAtIndex(i, true);
                break;
            }
    }

    @NonNull
    private ArrayAdapter<UserDefineObject> getSearchAdapter(ArrayList<UserDefineObject> items) {
        return new ArrayAdapter<>(getContext(), R.layout.list_item_white, items);
    }

    private void onClickShareMap() {
        mMapFragment.takeSnapshot(new DraggableMapFragment.SnapshotListener() {
            @Override
            public void onTakeSnapshot(Uri saveUri) {
                Intent intent = new Intent(Intent.ACTION_SEND);
                intent.putExtra(Intent.EXTRA_STREAM, saveUri);
                intent.setType(Utils.MIME_TYPE_IMAGE);
                startActivity(Intent.createChooser(intent, null));
            }
        });
    }
}
