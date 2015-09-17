package com.cohenadair.anglerslog.activities;

import android.os.Bundle;
import android.support.annotation.Nullable;
import android.support.v4.app.FragmentTransaction;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.Toolbar;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;

import com.cohenadair.anglerslog.R;
import com.cohenadair.anglerslog.fragments.DetailFragment;
import com.cohenadair.anglerslog.fragments.ManageFragment;
import com.cohenadair.anglerslog.fragments.MyListFragment;
import com.cohenadair.anglerslog.utilities.NavigationManager;
import com.cohenadair.anglerslog.utilities.fragment.FragmentData;
import com.cohenadair.anglerslog.utilities.fragment.FragmentInfo;

// TODO create FragmentManager utility class
// TODO rename themes for convention
// TODO rename fragment interface methods to be more specific

public class MainActivity extends AppCompatActivity implements
        MyListFragment.OnMyListFragmentInteractionListener
{

    private FragmentInfo mFragmentInfo;
    private NavigationManager mNavigationManager;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main_layout);

        showFragment(savedInstanceState);

        Toolbar toolbar = (Toolbar) findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);

        mNavigationManager = new NavigationManager(this);
        mNavigationManager.setUp();
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.menu_main, menu);
        return super.onCreateOptionsMenu(menu);
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        int id = item.getItemId();

        if (id == android.R.id.home) {
            mNavigationManager.onClickUpButton();
            return true;
        }

        return super.onOptionsItemSelected(item);
    }

    //region Getters & Setters
    public NavigationManager getNavigationManager() {
        return mNavigationManager;
    }
    //endregion

    public void showFragment(@Nullable Bundle savedInstanceState) {
        mFragmentInfo = FragmentData.fragmentInfo(this, FragmentData.getCurrentFragmentId());

        // avoid multiple fragments stacked on top of one another
        if (savedInstanceState != null)
            return;

        if (mFragmentInfo != null) {
            FragmentTransaction transaction = getSupportFragmentManager().beginTransaction();

            // add left panel
            transaction.replace(R.id.master_container, mFragmentInfo.getFragment(), mFragmentInfo.getTag());

            // add the right panel if needed
            if (isTwoPane())
                transaction.replace(R.id.detail_container, mFragmentInfo.detailFragment(), mFragmentInfo.detailTag());

            // commit changes
            transaction.commit();
        }
    }

    //region MyListFragment.OnListItemSelectedListener interface
    @Override
    public void onItemSelected(int position) {
        FragmentData.selectionPos(FragmentData.getCurrentFragmentId(), position);

        DetailFragment detailFragment = (DetailFragment)getSupportFragmentManager().findFragmentByTag(mFragmentInfo.detailTag());

        if (isTwoPane())
            detailFragment.update(position);
        else {
            // show the single catch fragment
            detailFragment = (DetailFragment)mFragmentInfo.detailFragment();

            FragmentTransaction transaction = getSupportFragmentManager().beginTransaction();
            transaction.replace(R.id.master_container, detailFragment)
                       .addToBackStack(null)
                       .commit();

            mNavigationManager.setActionBarTitle("");
        }
    }

    @Override
    public void onClickNewButton(View v) {
        ManageFragment manageFragment = mFragmentInfo.manageFragment();

        if (isTwoPane()) {
            // show as popup
            manageFragment.show(getSupportFragmentManager(), "dialog");
        } else {
            // show normally
            FragmentTransaction transaction = getSupportFragmentManager().beginTransaction();
            transaction.replace(R.id.master_container, manageFragment)
                       .addToBackStack(null)
                       .commit();

            mNavigationManager.setActionBarTitle(getResources().getString(R.string.new_text) + " " + mFragmentInfo.getName());
        }
    }
    //endregion

    //region Navigation
    @Override
    public void onBackPressed() {
        if (mNavigationManager.canGoBack())
            mNavigationManager.onBackPressed();
        else
            super.onBackPressed();
    }
    //endregion

    public boolean isTwoPane() {
        return getResources().getBoolean(R.bool.has_two_panes);
    }
}
