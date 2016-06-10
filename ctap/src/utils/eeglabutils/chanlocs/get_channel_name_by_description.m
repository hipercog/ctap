function cellStr = get_channel_name_by_description(EEG, description)
% GET_CHANNEL_NAME_BY_DESCRIPTION - A wrapper to get_refchan_inds()
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
cellStr = {EEG.chanlocs( get_refchan_inds(EEG, description) ).labels};
