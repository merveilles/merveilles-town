import { connect } from 'react-redux';
import { defineMessages, injectIntl } from 'react-intl';
import ColumnSettings from '../components/column_settings';
import { changeSetting } from '../../../actions/settings';
import { setFilter } from '../../../actions/notifications';
import { clearNotifications, requestBrowserPermission } from '../../../actions/notifications';
import { changeAlerts as changePushNotifications } from '../../../actions/push_notifications';
import { openModal } from '../../../actions/modal';
import { showAlert } from '../../../actions/alerts';

const messages = defineMessages({
  clearMessage: { id: 'notifications.clear_confirmation', defaultMessage: 'Are you sure you want to permanently clear all your notifications?' },
  clearConfirm: { id: 'notifications.clear', defaultMessage: 'Clear notifications' },
  permissionDenied: { id: 'notifications.permission_denied_alert', defaultMessage: 'Desktop notifications can\'t be enabled, as browser permission has been denied before' },
});

const mapStateToProps = state => ({
  settings: state.getIn(['settings', 'notifications']),
  pushSettings: state.get('push_notifications'),
  alertsEnabled: state.getIn(['settings', 'notifications', 'alerts']).includes(true),
  browserSupport: state.getIn(['notifications', 'browserSupport']),
  browserPermission: state.getIn(['notifications', 'browserPermission']),
});

const mapDispatchToProps = (dispatch, { intl }) => ({

  onChange (path, checked) {
    if (path[0] === 'push') {
      if (checked && typeof window.Notification !== 'undefined' && Notification.permission !== 'granted') {
        dispatch(requestBrowserPermission((permission) => {
          if (permission === 'granted') {
            dispatch(changePushNotifications(path.slice(1), checked));
          } else {
            dispatch(showAlert(undefined, messages.permissionDenied));
          }
        }));
      } else {
        dispatch(changePushNotifications(path.slice(1), checked));
      }
    } else if (path[0] === 'quickFilter') {
      dispatch(changeSetting(['notifications', ...path], checked));
      dispatch(setFilter('all'));
    } else if (path[0] === 'alerts' && checked && typeof window.Notification !== 'undefined' && Notification.permission !== 'granted') {
      if (checked && typeof window.Notification !== 'undefined' && Notification.permission !== 'granted') {
        dispatch(requestBrowserPermission((permission) => {
          if (permission === 'granted') {
            dispatch(changeSetting(['notifications', ...path], checked));
          } else {
            dispatch(showAlert(undefined, messages.permissionDenied));
          }
        }));
      } else {
        dispatch(changeSetting(['notifications', ...path], checked));
      }
    } else {
      dispatch(changeSetting(['notifications', ...path], checked));
    }
  },

  onClear () {
    dispatch(openModal('CONFIRM', {
      message: intl.formatMessage(messages.clearMessage),
      confirm: intl.formatMessage(messages.clearConfirm),
      onConfirm: () => dispatch(clearNotifications()),
    }));
  },

  onRequestNotificationPermission () {
    dispatch(requestBrowserPermission());
  },

});

export default injectIntl(connect(mapStateToProps, mapDispatchToProps)(ColumnSettings));
