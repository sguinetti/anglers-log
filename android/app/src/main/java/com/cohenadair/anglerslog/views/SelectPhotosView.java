package com.cohenadair.anglerslog.views;

import android.content.ClipData;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.res.TypedArray;
import android.media.MediaScannerConnection;
import android.net.Uri;
import android.os.Build;
import android.provider.MediaStore;
import android.support.v4.app.Fragment;
import android.support.v7.app.AlertDialog;
import android.util.AttributeSet;
import android.view.View;
import android.widget.ImageView;
import android.widget.LinearLayout;

import com.cohenadair.anglerslog.R;
import com.cohenadair.anglerslog.fragments.ManageContentFragment;
import com.cohenadair.anglerslog.utilities.AlertUtils;
import com.cohenadair.anglerslog.utilities.PermissionUtils;
import com.cohenadair.anglerslog.utilities.PhotoUtils;
import com.cohenadair.anglerslog.utilities.Utils;

import java.io.File;
import java.util.ArrayList;

/**
 * The SelectPhotosView is used to attach or take photos. All image manipulation is done in the
 * {@link PhotoUtils} class.
 *
 * Selected or taken photos are dynamically added to a horizontal scrolling ScrollView, and can be
 * removed with a long click.
 *
 * Photos taken with the user's Camera app are saved to public device storage and can be manipulated
 * by the user outside this application. This is done so the user has a full-resolution version of
 * the photo, and so the photo is kept if the user was to uninstall this application.
 *
 * All photos (taken or selected) are downsized and copied to private application storage where
 * they are used by this application.
 *
 * @author Cohen Adair
 */
public class SelectPhotosView extends LinearLayout {

    // indexes in a selection dialog
    private static final int PHOTO_ATTACH = 0;
    private static final int PHOTO_TAKE = 1;

    private InputButtonView mAddPhotoView;
    private LinearLayout mPhotosWrapper;
    private ArrayList<ImageView> mImageViews = new ArrayList<>();
    private ArrayList<String> mImagePaths = new ArrayList<>();
    private SelectPhotosInteraction mSelectPhotosInteraction;
    private File mPrivatePhotoFile; // used to save a version of the photo used by this application
    private Uri mPublicPhotoUri; // used to save a full resolution version of the photo for the user
    private Fragment mFragment;
    private int mPhotoType;

    private int mMaxPhotos = -1;
    private boolean mCanSelectMultiple = false;

    public interface SelectPhotosInteraction {
        File onGetPhotoFile();
        void onStartSelectionActivity(Intent intent, int requestCode);
    }

    public SelectPhotosView(Context context) {
        this(context, null);
        init(null);
    }

    public SelectPhotosView(Context context, AttributeSet attrs) {
        super(context, attrs);
        init(attrs);
    }

    private void init(AttributeSet attrs) {
        View view = inflate(getContext(), R.layout.view_selection_photos, this);

        mPhotosWrapper = (LinearLayout)view.findViewById(R.id.photos_wrapper);

        mAddPhotoView = (InputButtonView)view.findViewById(R.id.add_photo_view);
        mAddPhotoView.setOnClickPrimaryButton(new OnClickListener() {
            @Override
            public void onClick(View v) {
                showPhotoOptions();
            }
        });

        if (attrs != null) {
            TypedArray arr = getContext().getTheme().obtainStyledAttributes(attrs, R.styleable.SelectPhotosView, 0, 0);
            try {
                mMaxPhotos = arr.getInt(R.styleable.SelectPhotosView_maxPhotos, -1);
                mCanSelectMultiple = arr.getBoolean(R.styleable.SelectPhotosView_canSelectMultiple, false);
            } finally {
                arr.recycle();
            }
        }

        // multiple selection is only available on API 18+
        mCanSelectMultiple = mCanSelectMultiple && Build.VERSION.SDK_INT >= 18;
        if (mCanSelectMultiple) {
            mAddPhotoView.setPrimaryButtonHint(R.string.add_photos);
        }
    }

    //region Getters & Setters
    public void setSelectPhotosInteraction(SelectPhotosInteraction onSavePhotoListener) {
        mSelectPhotosInteraction = onSavePhotoListener;
    }

    public ArrayList<String> getImageNames() {
        ArrayList<String> names = new ArrayList<>();

        for (String path : mImagePaths)
            names.add(new File(path).getName());

        return names;
    }

    public void setMaxPhotos(int maxPhotos) {
        mMaxPhotos = maxPhotos;
    }

    public void setFragment(Fragment fragment) {
        mFragment = fragment;
    }
    //endregion

    /**
     * Should be called in the associated Fragment's onRequestPermissionsResult method.
     */
    public void onStoragePermissionsGranted() {
        mPrivatePhotoFile = mSelectPhotosInteraction.onGetPhotoFile();

        if (mPhotoType == PHOTO_ATTACH) {
            attachPhotos();
        }

        if (mPhotoType == PHOTO_TAKE) {
            takePhoto();
        }
    }

    private void attachPhotos() {
        mSelectPhotosInteraction.onStartSelectionActivity(
                PhotoUtils.pickPhotoIntent(getContext(), mCanSelectMultiple),
                ManageContentFragment.REQUEST_PHOTO);
    }

    private void takePhoto() {
        // photos taken from the camera are saved here
        File publicFile = PhotoUtils.publicPhotoFile(getContext(), mPrivatePhotoFile.getName());
        if (publicFile != null) {
            mPublicPhotoUri = Utils.getFileUri(getContext(), publicFile);
        } else {
            // needs to be reset for new/additional user photos
            // if this is null it just means the photo taken by the user will not be saved
            // to their gallery
            mPublicPhotoUri = null;
        }

        Intent photoIntent = PhotoUtils.takePhotoIntent();

        // make sure the camera is available on this device
        if (canTakePicture(photoIntent)) {
            if (mPublicPhotoUri != null) {
                photoIntent.putExtra(MediaStore.EXTRA_OUTPUT, mPublicPhotoUri);
                mSelectPhotosInteraction.onStartSelectionActivity(photoIntent,
                        ManageContentFragment.REQUEST_PHOTO);
            } else {
                Utils.showToast(getContext(), R.string.error_starting_camera);
            }
        } else {
            AlertUtils.showError(getContext(), R.string.error_camera_unavailable);
        }
    }

    private void openPhotoIntent(int takeOrAttach) {
        mPhotoType = takeOrAttach;

        if (PermissionUtils.isExternalStorageGranted(mFragment.getContext()))
            onStoragePermissionsGranted();
        else
            // results are handled in this view's associated Fragment
            PermissionUtils.requestExternalStorage(mFragment);
    }

    public void onPhotoIntentResult(Intent data) {
        if (data != null && data.getClipData() != null)
            addMultipleImagesFromIntent(data);
        else
            addSingleImageFromIntent(data);
    }

    private void addMultipleImagesFromIntent(Intent data) {
        ClipData clip = data.getClipData();

        for (int i = 0; i < clip.getItemCount(); i++) {
            Uri photoUri = clip.getItemAt(i).getUri();
            PhotoUtils.copyAndResizePhoto(getContext(), photoUri, mPrivatePhotoFile);

            if (!addImage(R.string.msg_error_saving_photos))
                break;

            // reset file for each image
            mPrivatePhotoFile = mSelectPhotosInteraction.onGetPhotoFile();
        }
    }

    private void addSingleImageFromIntent(Intent data) {
        // https://developer.android.com/reference/android/provider/MediaStore.html#ACTION_IMAGE_CAPTURE
        // the Uri passed to a ACTION_IMAGE_CAPTURE intent is where the image is saved
        // for some devices, like the Nexus 5X, it is the only way to read resulting data
        // for most devices, the photo Uri is passed to Intent.getData()
        Uri photoUri = (data == null || data.getData() == null) ? mPublicPhotoUri : data.getData();

        if (photoUri == null) {
            Utils.showToast(getContext(), R.string.msg_error_attaching_photo);
            return;
        }

        // scale down selected/taken photo and copy it to a private directory
        PhotoUtils.copyAndResizePhoto(getContext(), photoUri, mPrivatePhotoFile);

        // make sure photo taken shows up in the user's gallery
        if (mPublicPhotoUri != null) {
            String publicPhotoPath = mPublicPhotoUri.getPath();
            if (publicPhotoPath != null) {
                MediaScannerConnection.scanFile(getContext(), new String[]{publicPhotoPath}, null,
                        null);
            }
        }

        addImage(R.string.msg_error_saving_photo);
    }

    public void addImage(String path) {
        int size = getContext().getResources().getDimensionPixelSize(R.dimen.thumbnail_cell_size);

        LinearLayout.LayoutParams layoutParams = new LinearLayout.LayoutParams(size, size);
        layoutParams.setMargins(0, 0, 0, getContext().getResources().getDimensionPixelSize(R.dimen.margin_default));

        final ImageView img = new ImageView(getContext());
        img.setContentDescription("Image-" + mImageViews.size());
        img.setLayoutParams(layoutParams);
        img.setOnLongClickListener(new OnLongClickListener() {
            @Override
            public boolean onLongClick(View v) {
                AlertUtils.showDeleteConfirmation(getContext(), R.string.msg_delete_photo, new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int which) {
                        removeImage(img);
                    }
                });
                return false;
            }
        });
        PhotoUtils.thumbnailToImageView(getContext(), img, path, size, R.drawable.placeholder_square);

        mImageViews.add(img);
        mImagePaths.add(path);
        updateImageMargins();

        mPhotosWrapper.addView(img);

        // manage max photos
        if (mMaxPhotos != -1)
            if (mPhotosWrapper.getChildCount() >= mMaxPhotos)
                disableCamera();
    }

    public boolean addImage(int errMsgId) {
        if (mPrivatePhotoFile == null) {
            Utils.showToast(getContext(), errMsgId);
            return false;
        } else {
            addImage(mPrivatePhotoFile.getPath());
            return true;
        }
    }

    private void removeImage(ImageView img) {
        mImagePaths.remove(mImageViews.indexOf(img));
        mImageViews.remove(img);
        mPhotosWrapper.removeView(img);

        // manage max photos
        if (mMaxPhotos != -1)
            if (mPhotosWrapper.getChildCount() < mMaxPhotos)
                enableCamera();
    }

    /**
     * Updates the right margin of each ImageView to simulate spacing.
     */
    private void updateImageMargins() {
        for (int i = 0; i < mImageViews.size() - 1; i++) {
            LinearLayout.LayoutParams params = (LinearLayout.LayoutParams)mImageViews.get(i).getLayoutParams();
            params.setMargins(0, 0, getResources().getDimensionPixelSize(R.dimen.spacing_small), 0);
        }
    }

    private boolean canTakePicture(Intent intent) {
        return (mPrivatePhotoFile != null) && (intent.resolveActivity(getContext().getPackageManager()) != null);
    }

    private void enableCamera() {
        mAddPhotoView.setEnabled(true);
    }

    private void disableCamera() {
        mAddPhotoView.setEnabled(false);
    }

    private void showPhotoOptions() {
        if (!mAddPhotoView.isEnabled())
            return;

        int options = mCanSelectMultiple ? R.array.add_photo_options : R.array.add_photo_options_single;

        new AlertDialog.Builder(getContext())
                .setPositiveButton(R.string.button_cancel, new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int which) {
                        dialog.cancel();
                    }
                })
                .setItems(options, new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int which) {
                        openPhotoIntent(which);
                    }
                })
                .show();
    }

}
