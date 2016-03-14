package com.cohenadair.anglerslog.catches;

import android.content.Context;
import android.support.v7.widget.RecyclerView;
import android.view.View;
import android.view.ViewGroup;

import com.cohenadair.anglerslog.interfaces.OnClickInterface;
import com.cohenadair.anglerslog.model.Logbook;
import com.cohenadair.anglerslog.model.user_defines.Catch;
import com.cohenadair.anglerslog.model.user_defines.UserDefineObject;
import com.cohenadair.anglerslog.utilities.ListManager;

import java.util.ArrayList;

/**
 * The BaitListManager is a utility class for managing the catches list.
 * @author Cohen Adair
 */
public class CatchListManager {

    //region View Holder
    public static class ViewHolder extends ListManager.ViewHolder {

        private CatchListManager.Adapter.GetContentListener mListener;
        private Catch mCatch;

        public ViewHolder(View view, ListManager.Adapter adapter) {
            super(view, adapter);

            mListener = ((CatchListManager.Adapter)getAdapter()).getGetContentListener();
            setOnTouchFavoriteStarListener(new OnToggleFavoriteStarListener() {
                @Override
                public void onToggle(boolean isFavorite) {
                    mCatch.setIsFavorite(isFavorite);
                    Logbook.editCatch(mCatch.getId(), mCatch);
                }
            });

            initForComplexLayout();
        }

        public void setCatch(Catch aCatch) {
            mCatch = aCatch;

            setTitle(mCatch.getSpeciesAsString());
            setSubtitle(mCatch.getDateTimeAsString());
            setIsFavorite(mCatch.isFavorite());
            setImage(mCatch.getRandomPhoto());

            if (mCatch.getFishingSpot() != null)
                setSubSubtitle((mListener == null) ? mCatch.getFishingSpotAsString() : mListener.onGetSubSubtitle(mCatch));
        }

    }
    //endregion

    //region Adapter
    public static class Adapter extends ListManager.Adapter {

        private GetContentListener mGetContentListener;

        /**
         * Used for variations of {@link ViewHolder}, such as in a
         * {@link com.cohenadair.anglerslog.stats.BigCatchFragment}, where some of the content may
         * vary depending on how the list is being used.
         */
        public interface GetContentListener {
            String onGetSubSubtitle(Catch aCatch);
        }

        /**
         * @see com.cohenadair.anglerslog.utilities.ListSelectionManager.Adapter
         */
        public Adapter(Context context, ArrayList<UserDefineObject> items, boolean allowMultipleSelection, OnClickInterface callbacks) {
            super(context, items, allowMultipleSelection, callbacks);
        }

        public Adapter(Context context, ArrayList<UserDefineObject> items, OnClickInterface callbacks) {
            super(context, items, false, callbacks);
        }

        public Adapter(Context context, ArrayList<UserDefineObject> items, OnClickInterface onClickView, GetContentListener onGetContent) {
            super(context, items, false, onClickView);
            mGetContentListener = onGetContent;
        }

        public GetContentListener getGetContentListener() {
            return mGetContentListener;
        }

        // can't be overridden in the superclass because it needs to return a CatchListManager.ViewHolder
        @Override
        public ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
            return new ViewHolder(inflateComplexItem(parent), this);
        }

        @Override
        public void onBindViewHolder(RecyclerView.ViewHolder holder, int position) {
            ViewHolder catchHolder = (ViewHolder)holder;

            super.onBind(catchHolder, position);
            catchHolder.setCatch((Catch)getItem(position));
        }

    }
    //endregion

}
