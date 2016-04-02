package com.cohenadair.anglerslog.ui;

import android.support.test.rule.ActivityTestRule;
import android.support.test.runner.AndroidJUnit4;
import android.test.suitebuilder.annotation.LargeTest;

import com.cohenadair.anglerslog.R;
import com.cohenadair.anglerslog.activities.MainActivity;

import org.junit.After;
import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.runner.RunWith;

import static android.support.test.espresso.action.ViewActions.typeText;
import static com.cohenadair.anglerslog.ui.TestUtils.*;
import static com.cohenadair.anglerslog.ui.TestUtils.actionOnRecyclerViewItem;
import static com.cohenadair.anglerslog.ui.TestUtils.checkTextDisplayed;
import static com.cohenadair.anglerslog.ui.TestUtils.checkViewNotDisplayed;
import static com.cohenadair.anglerslog.ui.TestUtils.openAndSelectDrawerItem;
import static com.cohenadair.anglerslog.ui.TestUtils.performDescriptionClick;
import static com.cohenadair.anglerslog.ui.TestUtils.performHintClick;
import static com.cohenadair.anglerslog.ui.TestUtils.performTypeText;
import static com.cohenadair.anglerslog.ui.TestUtils.performViewClick;

/**
 * UI automated tests for viewing and managing primitive
 * {@link com.cohenadair.anglerslog.model.user_defines.UserDefineObject} objects.
 *
 * @author Cohen Adair
 */
@RunWith(AndroidJUnit4.class)
@LargeTest
public class PrimitiveTests {

    @Rule
    public ActivityTestRule<MainActivity> mActivityRule = new ActivityTestRule<>(MainActivity.class);

    @Before
    public void setUp() {

    }

    @After
    public void tearDown() {

    }

    @Test
    public void testManagePrimitives() {
        openAndSelectDrawerItem(R.string.drawer_catches);
        performViewClick(R.id.new_button);
        performHintClick(R.string.add_species);

        String test = "Aaa A Aaaa";
        String testExtended = "Aa Aa Aa";
        String test2 = test + testExtended;

        // add item
        performTypeText(R.id.new_item_edit, test);
        performViewClick(R.id.add_button);
        checkTextDisplayed(test);

        // edit item
        performViewClick(R.id.action_edit);
        actionOnRecyclerViewItem(R.id.content_recycler_view, 0, typeText(testExtended));
        performViewClick(R.id.action_check);
        checkTextDisplayed(test2);

        // delete item
        performViewClick(R.id.action_trash);
        actionOnRecyclerViewItem(R.id.content_recycler_view, 0, MyViewActions.clickChildView(R.id.delete_check_box));
        performViewClick(R.id.action_check);
        checkTextNotDisplayed(test2);

        // close dialog
        performDescriptionClick(R.string.back_description);
        checkViewNotDisplayed(R.id.manage_primitive_fragment);
    }
}
