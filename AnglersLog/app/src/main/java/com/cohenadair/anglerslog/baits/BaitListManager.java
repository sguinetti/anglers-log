package com.cohenadair.anglerslog.baits;

import android.content.Context;
import android.support.v7.widget.RecyclerView;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import com.cohenadair.anglerslog.R;
import com.cohenadair.anglerslog.interfaces.OnClickInterface;
import com.cohenadair.anglerslog.model.user_defines.Bait;
import com.cohenadair.anglerslog.model.user_defines.BaitCategory;
import com.cohenadair.anglerslog.model.user_defines.UserDefineObject;
import com.cohenadair.anglerslog.utilities.ListManager;
import com.cohenadair.anglerslog.utilities.PhotoUtils;
import com.cohenadair.anglerslog.views.TitleSubTitleView;

import java.io.File;
import java.util.ArrayList;

/**
 * The BaitListManager is a utility class for managing the catches list.
 * @author Cohen Adair
 */
public class BaitListManager {

    //region View Holder
    public static class ViewHolder extends ListManager.ViewHolder {

        private ListManager.Adapter mAdapter;
        private ImageView mImageView;
        private TextView mCategoryTextView;
        private TitleSubTitleView mTitleSubTitleView;
        private View mSeparator;

        public ViewHolder(View view, ListManager.Adapter adapter) {
            super(view, adapter);

            mAdapter = adapter;
            mImageView = (ImageView)view.findViewById(R.id.image_view);
            mCategoryTextView = (TextView)view.findViewById(R.id.category_text_view);
            mSeparator = view.findViewById(R.id.cell_separator);
            mTitleSubTitleView = (TitleSubTitleView)view.findViewById(R.id.content_view);
        }

        public void setBait(Bait bait, int position) {
            mTitleSubTitleView.setTitle(bait.getName());
            mTitleSubTitleView.setSubtitle(bait.getCategoryName());
            mTitleSubTitleView.setSubSubtitle(bait.getCatchCountAsString(getContext()));

            // thumbnail stuff
            // if the image doesn't exist or can't be read, a default icon is shown
            boolean fileExists = false;
            String randomPhoto = bait.getRandomPhoto();
            String randomPhotoPath = "";

            if (randomPhoto != null)
                randomPhotoPath = PhotoUtils.privatePhotoPath(randomPhoto);

            if (randomPhotoPath != null)
                fileExists = new File(randomPhotoPath).exists();

            if (fileExists) {
                int thumbSize = getContext().getResources().getDimensionPixelSize(R.dimen.thumbnail_size);
                PhotoUtils.thumbnailToImageView(mImageView, randomPhotoPath, thumbSize, R.drawable.no_catch_photo);
            } else
                mImageView.setImageResource(R.drawable.no_catch_photo);

            updateView(mSeparator, position);

            // hide last separator for BaitCategory "sub-lists"
            if (position + 1 < mAdapter.getItemCount()) {
                boolean isLast = mAdapter.getItem(position + 1) instanceof BaitCategory;
                mSeparator.setVisibility(isLast ? View.INVISIBLE : View.VISIBLE);
            }

            mCategoryTextView.setVisibility(View.GONE);
            initViewVisibility(View.VISIBLE);
        }

        public void setBaitCategory(BaitCategory category) {
            mCategoryTextView.setVisibility(View.VISIBLE);
            mCategoryTextView.setText(category.getName());
            initViewVisibility(View.GONE);
        }

        private void initViewVisibility(int visibility) {
            mTitleSubTitleView.setVisibility(visibility);
            mImageView.setVisibility(visibility);
        }
    }
    //endregion

    //region Adapter
    public static class Adapter extends ListManager.Adapter {

        public Adapter(Context context, ArrayList<UserDefineObject> items, boolean allowMultipleSelection, OnClickInterface callbacks) {
            super(context, items, allowMultipleSelection, callbacks);
        }

        // can't be overridden in the superclass because it needs to return a BaitListManager.ViewHolder
        @Override
        public ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
            LayoutInflater inflater = LayoutInflater.from(getContext());
            View view = inflater.inflate(R.layout.list_item_bait, parent, false);
            return new ViewHolder(view, this);
        }

        @Override
        public void onBindViewHolder(RecyclerView.ViewHolder holder, int position) {
            ViewHolder baitHolder = (ViewHolder)holder;
            UserDefineObject item = getItem(position);

            super.onBind(baitHolder, position);

            if (item instanceof Bait)
                baitHolder.setBait((Bait)item, position);
            else
                baitHolder.setBaitCategory((BaitCategory)item);
        }

    }
    //endregion

}
