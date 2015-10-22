package com.cohenadair.anglerslog.utilities;

import android.content.Context;
import android.content.Intent;
import android.content.res.Resources;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.media.ExifInterface;
import android.media.ThumbnailUtils;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Environment;
import android.provider.MediaStore;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.util.Log;
import android.widget.ImageView;

import com.cohenadair.anglerslog.R;
import com.cohenadair.anglerslog.model.Logbook;
import com.cohenadair.anglerslog.model.user_defines.Catch;
import com.cohenadair.anglerslog.model.user_defines.UserDefineObject;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.lang.ref.WeakReference;
import java.util.ArrayList;

/**
 * Any utility functions that have anything to do with photos/photo manipulation.
 * Created by Cohen Adair on 2015-10-18.
 */
public class PhotoUtils {

    private static final String TAG = "PhotoUtils";
    private static Context mContext;
    private static PhotoCache mCache;

    private PhotoUtils() { }

    public static void init(Context context) {
        PhotoUtils.mContext = context;
        mCache = new PhotoCache(context, 1024 * 1024 * 10, 0.125, "bitmap_cache");
    }

    @NonNull
    public static Intent pickPhotoIntent() {
        Intent intent = new Intent();
        intent.setType("image/*");
        intent.setAction(Intent.ACTION_GET_CONTENT);
        return Intent.createChooser(intent, mContext.getResources().getString(R.string.select_photo));
    }

    @NonNull
    public static Intent takePhotoIntent() {
        return new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
    }

    /**
     * Scales the image at the specified path to the specified dimension. This method should be
     * executed away from the UI thread. Keeps aspect ratio.
     *
     * @param path The path to the image to scale.
     * @param destWidth The destination width.
     * @param destHeight The destination height.
     * @return A Bitmap object of the new
     */
    private static Bitmap scaledBitmap(String path, int destWidth, int destHeight) {
        // read in the dimensions of the image on disk
        BitmapFactory.Options options = new BitmapFactory.Options();
        options.inJustDecodeBounds = true;
        BitmapFactory.decodeFile(path, options);

        options = scaledBitmapSampleSize(options.outWidth, options.outHeight, destWidth, destHeight);

        // read in and create the final bitmap
        return BitmapFactory.decodeFile(path, options);
    }

    /**
     * Scales the photo at the given Uri to the specified size. Keeps aspect ratio. The longest
     * dimension of the photo will be scaled down to `longestDestLength`.
     *
     * @param uri The Uri of the photo to be scaled.
     * @param longestDestLength The longest side length for the destination photo, in pixels.
     * @return A scaled Bitmap version of the photo at the specified Uri, or null if the scale
     * failed.
     */
    @Nullable
    private static Bitmap scaledBitmap(Uri uri, int longestDestLength) {
        InputStream in = null;

        // create InputStream from Uri
        try {
            in = mContext.getContentResolver().openInputStream(uri);

            // read in the dimensions of the image on disk
            BitmapFactory.Options options = new BitmapFactory.Options();
            options.inJustDecodeBounds = true;
            BitmapFactory.decodeStream(in, null, options);

            if (in != null)
                in.close();

            options = scaledBitmapSampleSize(options.outWidth, options.outHeight, longestDestLength, longestDestLength);

            // reset InputStream as it cannot be used more than once
            in = mContext.getContentResolver().openInputStream(uri);

            // read in and create the final bitmap
            return BitmapFactory.decodeStream(in, null, options);

        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            try {
                if (in != null)
                    in.close();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }

        return null;
    }

    /**
     * Gets the scale factor to scale the source size to the destination size.
     *
     * @param srcWidth Original width, in pixels.
     * @param srcHeight Original height, in pixels.
     * @param destWidth New width, in pixels.
     * @param destHeight New height, in pixels.
     * @return A BitmapFactory.Options object with the `inSampleSize` field set.
     */
    private static BitmapFactory.Options scaledBitmapSampleSize(int srcWidth, int srcHeight, int destWidth, int destHeight) {
        // figure out how much to scale by
        int inSampleSize = 1;
        if (srcHeight > destHeight || srcWidth > destWidth)
            if (srcWidth < srcHeight)
                inSampleSize = (int)Math.ceil((double) srcHeight / (double) destHeight);
            else
                inSampleSize = (int)Math.ceil((double) srcWidth / (double) destWidth);

        BitmapFactory.Options options = new BitmapFactory.Options();
        options.inSampleSize = inSampleSize;

        return options;
    }

    /**
     * Takes a photo at a given path, scales it, generates a thumbnail of specified size, and
     * inserts into the given ImageView. This entire process is done asynchronously using
     * {@link com.cohenadair.anglerslog.utilities.PhotoUtils.BitmapAsyncTask}.
     *
     * @param imageView The ImageView to display the thumbnail.
     * @param path The path to the photo.
     * @param size The size of the ImageView, in pixels.
     */
    public static void thumbnailToImageView(ImageView imageView, String path, int size, int placeHolderResId) {
        Bitmap placeHolder = BitmapFactory.decodeResource(mContext.getResources(), placeHolderResId);
        Bitmap fromCache = mCache.bitmapFromMemory(path, size);

        if (fromCache != null) {
            Log.i(TAG, "Found bitmap in MEMORY cache!");
            imageView.setImageBitmap(fromCache);
        } else if (cancelPotentialWork(path, imageView)) {
            final BitmapAsyncTask task = new BitmapAsyncTask(imageView, size, size, true);
            final AsyncDrawable asyncDrawable = new AsyncDrawable(mContext.getResources(), placeHolder, task);
            imageView.setImageDrawable(asyncDrawable);
            task.execute(path);
        }
    }

    /**
     * Rotates the specified bitmap to the correct orientation.
     *
     * @param path The path to the photo file.
     * @param bmp The Bitmap representative of the photo file.
     * @return A correctly rotated Bitmap.
     */
    private static Bitmap fixOrientation(String path, Bitmap bmp) {
        try {
            ExifInterface exif = new ExifInterface(path);
            int orientation = exif.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_UNDEFINED);

            switch (orientation) {
                case ExifInterface.ORIENTATION_ROTATE_90:
                    bmp = rotateBitmap(bmp, 90);
                    break;

                case ExifInterface.ORIENTATION_ROTATE_180:
                    bmp = rotateBitmap(bmp, 180);
                    break;

                case ExifInterface.ORIENTATION_ROTATE_270:
                    bmp = rotateBitmap(bmp, 270);
                    break;
            }

        } catch (IOException e) {
            Log.d(TAG, "Error extracting ExifInterface from file: " + path);
            e.printStackTrace();
        }

        return bmp;
    }

    /**
     * Rotates the specified bitmap by the specified degrees.
     *
     * @param bmp The Bitmap to rotate.
     * @param degrees How much to rotate the Bitmap.
     * @return A rotated Bitmap.
     */
    private static Bitmap rotateBitmap(Bitmap bmp, int degrees) {
        Matrix matrix = new Matrix();
        matrix.postRotate(degrees);
        return Bitmap.createBitmap(bmp, 0, 0, bmp.getWidth(), bmp.getHeight(), matrix, true);
    }

    /**
     * Gets the photo storage directory for this application.
     *
     * @return A File object of the storage directory.
     */
    private static File privatePhotoDirectory() {
        return mContext.getExternalFilesDir(Environment.DIRECTORY_PICTURES);
    }

    /**
     * Gets a pointer to a file where a new photo can be saved. This location is private to this
     * application.
     *
     * @param fileName The name of the new photo.
     * @return A File object pointing to the photo's storage location.
     */
    @Nullable
    public static File privatePhotoFile(String fileName) {
        File externalFilesDir = privatePhotoDirectory();

        if (externalFilesDir == null)
            return null;

        return new File(externalFilesDir, fileName);
    }

    /**
     * Gets the full path to the specified file name.
     *
     * @param fileName The name of the file to get.
     * @return A String of the file's path.
     */
    public static String privatePhotoPath(String fileName) {
        File f = privatePhotoFile(fileName);
        return (f == null) ? null : f.getPath();
    }

    /**
     * Gets a pointer to a file location in the devices public storage.
     *
     * @param fileName The name of the file to to be created.
     * @return A File object if the directory exists, null otherwise.
     */
    @Nullable
    public static File publicPhotoFile(String fileName) {
        String photosPath = Environment.DIRECTORY_PICTURES + mContext.getResources().getString(R.string.app_photos_dir);
        File publicDirectory = Environment.getExternalStoragePublicDirectory(photosPath);

        if (publicDirectory.mkdirs() || publicDirectory.isDirectory())
            return new File(publicDirectory, fileName);

        return null;
    }

    /**
     * Copies a photo to a new location and scales it down to `R.dimen.max_photo_size` pixels.
     *
     * @param srcUri The source Uri of the photo.
     * @param destFile The destination file the Bitmap will be written to.
     */
    public static void copyAndResizePhoto(Uri srcUri, File destFile) {
        // if the Uri is content (in public storage), extract the actual path
        String path = srcUri.getScheme().equals("content") ? actualUriPath(srcUri) : srcUri.getPath();

        if (destFile != null) {
            int longestSideLength = mContext.getResources().getInteger(R.integer.max_photo_size);
            Bitmap scaledBitmap = fixOrientation(path, scaledBitmap(srcUri, longestSideLength));
            PhotoCache.savePhoto(scaledBitmap, destFile);
        }
    }

    /**
     * Get a file path from a Uri. This will get the the path for Storage Access Framework
     * Documents, as well as the _data field for the MediaStore and other file-based
     * ContentProviders.
     *
     * This method was derived from the `getPath` method in <a href="https://github.com/iPaulPro/aFileChooser/blob/master/aFileChooser/src/com/ipaulpro/afilechooser/utils/FileUtils.java">iPaulPro's aFileChooser FileUtils.java</a>
     *
     * @param uri The Uri to query.
     * @return A String representing the actual Uri path.
     */
    private static String actualUriPath(final Uri uri) {
        boolean isMinKitKat = Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT;

        if (isMinKitKat) {
            Uri contentUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI;

            String selection = "_id=?";
            String[] selectionArgs = new String[] { devicePhotoId(uri) };

            return dataColumnValue(contentUri, selection, selectionArgs);
        } else
            return dataColumnValue(uri, null, null);
    }

    /**
     * Get the value of the data column for this Uri. This is useful for MediaStore Uris, and other
     * file-based ContentProviders.
     *
     * This method was extracted from <a href="https://github.com/iPaulPro/aFileChooser/blob/master/aFileChooser/src/com/ipaulpro/afilechooser/utils/FileUtils.java">iPaulPro's aFileChooser FileUtils.java</a>
     *
     * @param uri The Uri to query.
     * @param selection (Optional) Filter used in the query.
     * @param selectionArgs (Optional) Selection arguments used in the query.
     * @return The value of the _data column, which is typically a file path.
     */
    @Nullable
    private static String dataColumnValue(Uri uri, String selection, String[] selectionArgs) {
        Cursor cursor = null;
        final String column = MediaStore.Images.Media.DATA;
        final String[] projection = { column };

        try {
            cursor = mContext.getContentResolver().query(uri, projection, selection, selectionArgs, null);
            if (cursor != null && cursor.moveToFirst()) {
                final int column_index = cursor.getColumnIndexOrThrow(column);
                return cursor.getString(column_index);
            }
        } catch (Exception e) {
            Log.e(TAG, "Invalid Uri passed to dataColumnValue, returning null.");
        } finally {
            if (cursor != null)
                cursor.close();
        }

        return null;
    }

    /**
     * Gets the id of the photo at the specified Uri. This only works in API level 19+. For example,
     * a Uri with path: `content://com.android.providers.media.documents/document/image:62` would
     * result with a photo id of "62".
     *
     * @param uri The Uri of the photo.
     * @return A String of the photo's id.
     */
    private static String devicePhotoId(Uri uri) {
        String photoId = null;
        Cursor cursor = mContext.getContentResolver().query(uri, null, null, null, null);

        if (cursor != null && cursor.moveToFirst()) {
            photoId = cursor.getString(0);
            photoId = photoId.substring(photoId.lastIndexOf(":") + 1);
        }

        if (cursor != null)
            cursor.close();

        return photoId;
    }

    /**
     * Cross references the photo files in private storage with the names of photos used throughout
     * the application and deletes photos that aren't used.
     */
    private static void cleanPhotos() {
        File photosDir = privatePhotoDirectory();
        boolean found;
        int numDeleted = 0;

        if (photosDir != null && photosDir.isDirectory()) {
            File[] photoFiles = photosDir.listFiles();

            for (int i = photoFiles.length - 1; i >= 0; i--) {
                found = false;

                // check all Catch objects for the current File
                for (UserDefineObject aCatch : Logbook.getCatches()) {
                    if (((Catch) aCatch).getPhotoFileNames().indexOf(photoFiles[i].getName()) >= 0) {
                        found = true;
                        break;
                    }
                }

                // TODO add Bait photos here

                if (!found)
                    numDeleted += (photoFiles[i].delete()) ? 1 : 0;
            }
        }

        Log.i(TAG, "Cleaned " + numDeleted + " photo files from private storage.");
    }

    private static void cleanCache() {
        ArrayList<String> photoNames = new ArrayList<>();
        for (UserDefineObject aCatch : Logbook.getCatches())
            photoNames.addAll(((Catch)aCatch).getPhotoFileNames());

        mCache.cleanDisk(photoNames);
    }

    /**
     * Cleans up photo files in another thread. See `cleanPhotos(...)`.
     */
    public static void cleanPhotosAsync() {
        Thread thread = new Thread(new Runnable() {
            @Override
            public void run() {
                cleanPhotos();
                cleanCache();
            }
        });
        thread.start();
    }

    //region Async Bitmap Utilities
    /**
     * This section was created from the Android tutorial,
     * <a href="http://developer.android.com/training/displaying-bitmaps/index.html">Displaying Bitmaps Efficiently</a>.
     */

    /**
     * The BitmapAsyncTask class is used to scale and/or generate a thumbnail for the image at
     * a given path and insert that bitmap into the given ImageView.
     *
     * This is required so the UI thread isn't locked up while loading Bitmap objects.
     */
    private static class BitmapAsyncTask extends AsyncTask<String, Void, Bitmap> {
        private final WeakReference<ImageView> mImageViewRef;
        private String mPath = null;
        private int mWidth, mHeight;
        private boolean mGenerateThumb;

        /**
         * Sets up the AsyncTask for execution.
         * @param imageView The ImageView that holds the new Bitmap.
         * @param width The width of the scaled Bitmap, in pixels.
         * @param height The height of the scaled Bitmap, in Pixels.
         * @param thumb True to use a thumbnail image (square), false for original size ratio.
         */
        public BitmapAsyncTask(ImageView imageView, int width, int height, boolean thumb) {
            mImageViewRef = new WeakReference<>(imageView);
            mWidth = width;
            mHeight = height;
            mGenerateThumb = thumb;
        }

        @Override
        protected Bitmap doInBackground(String... params) {
            mPath = params[0];
            Bitmap scaledBitmap = mCache.bitmapFromDisk(mPath, mWidth);

            // process image if it isn't cached
            if (scaledBitmap == null) {
                scaledBitmap = scaledBitmap(mPath, mWidth, mHeight);

                // get thumbnail if needed
                if (mGenerateThumb) {
                    int size = (mWidth > mHeight) ? mHeight : mWidth; // get the smaller of the width/height
                    scaledBitmap = ThumbnailUtils.extractThumbnail(scaledBitmap, size, size);
                }
            } else
                Log.i(TAG, "Bitmap found in DISK cache!");

            // cache bitmap to use later
            mCache.addBitmap(mPath, mWidth, scaledBitmap);

            return scaledBitmap;
        }

        @Override
        protected void onPostExecute(Bitmap bitmap) {
            if (isCancelled())
                bitmap = null;

            if (bitmap != null) {
                final ImageView imageView = mImageViewRef.get();
                final BitmapAsyncTask bitmapAsyncTask = bitmapAsyncTask(imageView);

                if (this == bitmapAsyncTask)
                    imageView.setImageBitmap(bitmap);
            }
        }

        public String getPath() {
            return mPath;
        }
    }

    /**
     * The AsyncDrawable class is used so the ImageView can store a reference back to it's
     * BitmapAsyncTask. A BitmapDrawable is used so that a placeholder image can be displayed in the
     * ImageView while the task is being completed.
     */
    private static class AsyncDrawable extends BitmapDrawable {
        private final WeakReference<BitmapAsyncTask> mBitmapAsyncTaskRef;

        public AsyncDrawable(Resources resources, Bitmap bitmap, BitmapAsyncTask bitmapAsyncTask) {
            super(resources, bitmap);
            mBitmapAsyncTaskRef = new WeakReference<>(bitmapAsyncTask);
        }

        public BitmapAsyncTask getBitmapAsyncTask() {
            return mBitmapAsyncTaskRef.get();
        }
    }

    /**
     * Checks to see if another running task is already associated with the given ImageView. If so,
     * it attempts to cancel the task. In a small number of cases the new task will match an
     * existing task (such as in a ListView or GridView).
     *
     * @param path The path of the photo.
     * @param imageView The ImageView to check for BitmapAsyncTask.
     * @return True if there is no task associated with the ImageView, or the task was cancelled,
     * false otherwise.
     */
    private static boolean cancelPotentialWork(String path, ImageView imageView) {
        final BitmapAsyncTask bitmapAsyncTask = bitmapAsyncTask(imageView);

        if (bitmapAsyncTask != null) {
            final String bitmapPath = bitmapAsyncTask.getPath();

            // if the path is not yet set or it differs from the new data
            if (bitmapPath == null || !bitmapPath.equals(path))
                // cancel previous task
                bitmapAsyncTask.cancel(true);
            else
                // the same work is already in progress
                return false;
        }

        // no task associated with the ImageView, or an existing task was cancelled
        return true;
    }

    /**
     * Retrieves the BitmapAsyncTask object associated with the specified ImageView.
     *
     * @param imageView The ImageView with associated BitmapAsyncTask.
     * @return A BitmapAsyncTask associated with the ImageView, or null if no such object exists.
     */
    private static BitmapAsyncTask bitmapAsyncTask(ImageView imageView) {
        if (imageView != null) {
            final Drawable drawable = imageView.getDrawable();

            if (drawable instanceof AsyncDrawable) {
                final AsyncDrawable asyncDrawable = (AsyncDrawable)drawable;
                return asyncDrawable.getBitmapAsyncTask();
            }
        }

        return null;
    }
    //endregion

}
