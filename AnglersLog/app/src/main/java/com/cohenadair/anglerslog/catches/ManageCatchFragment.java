package com.cohenadair.anglerslog.catches;

import android.app.Activity;
import android.app.DatePickerDialog;
import android.app.TimePickerDialog;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.DatePicker;
import android.widget.TimePicker;

import com.cohenadair.anglerslog.R;
import com.cohenadair.anglerslog.activities.MyListSelectionActivity;
import com.cohenadair.anglerslog.fragments.DatePickerFragment;
import com.cohenadair.anglerslog.fragments.ManageContentFragment;
import com.cohenadair.anglerslog.fragments.ManagePrimitiveFragment;
import com.cohenadair.anglerslog.fragments.TimePickerFragment;
import com.cohenadair.anglerslog.model.Logbook;
import com.cohenadair.anglerslog.model.user_defines.Catch;
import com.cohenadair.anglerslog.model.user_defines.Species;
import com.cohenadair.anglerslog.model.user_defines.UserDefineObject;
import com.cohenadair.anglerslog.utilities.LayoutSpecManager;
import com.cohenadair.anglerslog.utilities.PhotoUtils;
import com.cohenadair.anglerslog.utilities.PrimitiveController;
import com.cohenadair.anglerslog.utilities.Utils;
import com.cohenadair.anglerslog.views.SelectPhotosView;
import com.cohenadair.anglerslog.views.SelectionView;

import java.io.File;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.UUID;

/**
 * The ManageBaitFragment is used to add and edit catches.
 */
public class ManageCatchFragment extends ManageContentFragment {

    private Catch mNewCatch;

    private SelectionView mDateView;
    private SelectionView mTimeView;
    private SelectionView mSpeciesView;
    private SelectionView mBaitView;

    private SelectPhotosView mSelectPhotosView;

    public ManageCatchFragment() {
        // Required empty public constructor
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_manage_catch, container, false);

        initDateTimeView(view);
        initSpeciesView(view);
        initBaitView(view);
        initSelectPhotosView(view);

        return view;
    }

    /**
     * Needed to initialize Catch and editing settings because there is ever only one instance of
     * this fragment that is reused throughout the application's lifecycle.
     */
    @Override
    public void onResume() {
        super.onResume();

        // do not initialize Catches if we were paused
        if (mNewCatch == null)
            if (isEditing()) {
                Catch oldCatch = Logbook.getCatch(getEditingId());

                if (oldCatch != null) {
                    // populate the photos view with the existing photos
                    ArrayList<String> photos = oldCatch.getPhotos();
                    for (String str : photos)
                        mSelectPhotosView.addImage(PhotoUtils.privatePhotoPath(str));
                }

                mNewCatch = new Catch(oldCatch, true);
            } else
                mNewCatch = new Catch(new Date());

        updateViews();
    }

    @Override
    public void onAttach(Context context) {
        super.onAttach(context);
    }

    @Override
    public void onDetach() {
        super.onDetach();
        mNewCatch = null;
    }

    @Override
    public boolean addObjectToLogbook() {
        boolean result = false;

        if (verifyUserInput()) {
            mNewCatch.setPhotos(mSelectPhotosView.getImageNames());

            if (isEditing()) {
                // edit catch
                result = Logbook.editCatch(getEditingId(), mNewCatch);
                int msgId = result ? R.string.success_catch_edit : R.string.error_catch_edit;
                Utils.showToast(getActivity(), msgId);
            } else {
                // add catch
                result = Logbook.addCatch(mNewCatch);
                int msgId = result ? R.string.success_catch : R.string.error_catch;
                Utils.showToast(getActivity(), msgId);
            }
        }

        return result;
    }

    @Override
    public void onDismiss() {
        PhotoUtils.cleanPhotosAsync();
    }

    /**
     * Validates the user's input.
     * @return True if the input is valid, false otherwise.
     */
    private boolean verifyUserInput() {
        // species
        if (mNewCatch.getSpecies() == null) {
            Utils.showErrorAlert(getActivity(), R.string.error_catch_species);
            return false;
        }

        return true;
    }

    //region Date & Time
    private void initDateTimeView(View view) {
        mDateView = (SelectionView)view.findViewById(R.id.date_layout);
        mDateView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                DatePickerFragment datePicker = new DatePickerFragment();
                datePicker.setOnDateSetListener(new DatePickerDialog.OnDateSetListener() {
                    @Override
                    public void onDateSet(DatePicker view, int year, int monthOfYear, int dayOfMonth) {
                        updateCalendar();
                        Calendar c = Calendar.getInstance();
                        int hours = c.get(Calendar.HOUR_OF_DAY);
                        int minutes = c.get(Calendar.MINUTE);
                        c.set(year, monthOfYear, dayOfMonth, hours, minutes);
                        updateDateView(c.getTime());
                    }
                });
                datePicker.show(getFragmentManager(), "datePicker");
            }
        });

        mTimeView = (SelectionView)view.findViewById(R.id.time_layout);
        mTimeView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                TimePickerFragment timePicker = new TimePickerFragment();
                timePicker.setOnTimeSetListener(new TimePickerDialog.OnTimeSetListener() {
                    @Override
                    public void onTimeSet(TimePicker view, int hourOfDay, int minute) {
                        updateCalendar();
                        Calendar c = Calendar.getInstance();
                        int year = c.get(Calendar.YEAR);
                        int month = c.get(Calendar.MONTH);
                        int day = c.get(Calendar.DAY_OF_MONTH);
                        c.set(year, month, day, hourOfDay, minute);
                        updateTimeView(c.getTime());
                    }
                });
                timePicker.show(getFragmentManager(), "timePicker");
            }
        });
    }

    /**
     * Updates the date view's text.
     * @param date The date to display in the view. Only looks at the date portion.
     */
    private void updateDateView(Date date) {
        mNewCatch.setDate(date);
        mDateView.setSubtitle(mNewCatch.getDateAsString());
    }

    /**
     * Updates the time view's text.
     * @param date The date to display in the view. Only looks at the time portion.
     */
    private void updateTimeView(Date date) {
        mNewCatch.setDate(date);
        mTimeView.setSubtitle(mNewCatch.getTimeAsString());
    }

    /**
     * Update the different views based on the current Catch object to display.
     */
    private void updateViews() {
        mDateView.setSubtitle(mNewCatch.getDateAsString());
        mTimeView.setSubtitle(mNewCatch.getTimeAsString());

        mSpeciesView.setSubtitle(mNewCatch.getSpecies() != null ? mNewCatch.getSpeciesAsString() : "");
    }

    /**
     * Resets the calendar's time to the current catch's time.
     */
    private void updateCalendar() {
        Calendar.getInstance().setTime(mNewCatch.getDate());
    }
    //endregion

    private void initSpeciesView(View view) {
        mSpeciesView = (SelectionView)view.findViewById(R.id.species_layout);
        mSpeciesView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                final ManagePrimitiveFragment fragment = ManagePrimitiveFragment.newInstance(PrimitiveController.SPECIES);

                fragment.setOnDismissInterface(new ManagePrimitiveFragment.OnDismissInterface() {
                    @Override
                    public void onDismiss(UserDefineObject selectedItem) {
                        mNewCatch.setSpecies((Species)selectedItem);
                        mSpeciesView.setSubtitle(mNewCatch.getSpeciesAsString());
                    }
                });

                fragment.show(getFragmentManager(), "dialog");
            }
        });
    }

    private void initBaitView(View view) {
        mBaitView = (SelectionView)view.findViewById(R.id.bait_layout);
        mBaitView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                startSelectionActivity(LayoutSpecManager.LAYOUT_BAITS);
            }
        });
    }

    private void initSelectPhotosView(View view) {
        mSelectPhotosView = (SelectPhotosView)view.findViewById(R.id.select_photos_view);
        mSelectPhotosView.setSelectPhotosInteraction(new SelectPhotosView.SelectPhotosInteraction() {
            @Override
            public File onGetPhotoFile() {
                UUID id = isEditing() ? getEditingId() : null;
                return PhotoUtils.privatePhotoFile(mNewCatch.getNextPhotoName(id));
            }

            @Override
            public void onStartSelectionActivity(Intent intent, int requestCode) {
                getParentFragment().startActivityForResult(intent, requestCode);
            }
        });
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        if (resultCode != Activity.RESULT_OK)
            return;

        if (requestCode == REQUEST_PHOTO) {
            mSelectPhotosView.onPhotoIntentResult(data);
            return;
        }

        if (requestCode == REQUEST_SELECTION) {
            UUID id = UUID.fromString(data.getStringExtra(MyListSelectionActivity.EXTRA_SELECTED_ID));
            Log.d("ManageBaitFragment", "Selected ID: " + id.toString());
            return;
        }

        super.onActivityResult(requestCode, resultCode, data);
    }

}